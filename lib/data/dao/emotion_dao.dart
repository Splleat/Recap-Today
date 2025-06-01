import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:recap_today/model/emotion_model.dart';
import 'package:recap_today/model/sync_status.dart'; // Added import

class EmotionDao {
  final Database db;
  static const String tableName = 'emotion_records';
  final Uuid _uuid = const Uuid();
  static const String columnServerId =
      'serverId'; // Added serverId column constant

  EmotionDao(this.db);

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        $columnServerId TEXT UNIQUE, // Added serverId column
        date TEXT NOT NULL,
        hour INTEGER NOT NULL,
        emotionType TEXT NOT NULL, 
        notes TEXT,
        lastSynced TEXT,
        isDeleted INTEGER DEFAULT 0,
        syncStatus TEXT,          
        updatedAt TEXT,           
        UNIQUE (date, hour)
      )
    ''');
  }

  static Future<void> upgradeTable(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 13) {
      try {
        await db.execute('ALTER TABLE $tableName ADD COLUMN lastSynced TEXT;');
      } catch (e) {
        print('Error adding lastSynced column: $e');
      }
      try {
        await db.execute(
          'ALTER TABLE $tableName ADD COLUMN isDeleted INTEGER DEFAULT 0;',
        );
      } catch (e) {
        print('Error adding isDeleted column: $e');
      }
    }
    if (oldVersion < 14) {
      try {
        await db.execute('ALTER TABLE $tableName ADD COLUMN syncStatus TEXT;');
      } catch (e) {
        print('Error adding syncStatus column: $e');
      }
      try {
        await db.execute('ALTER TABLE $tableName ADD COLUMN updatedAt TEXT;');
      } catch (e) {
        print('Error adding updatedAt column: $e');
      }
      // Add serverId column if it doesn't exist
      // This should ideally be part of a new version increment.
      // For the purpose of this refactor, we add it here if not present.
      // A more robust migration would check the actual schema or use a higher version number.
      try {
        // Note: Checking if column exists before adding is complex in sqflite.
        // We rely on this upgrade logic running for the correct oldVersion.
        // If oldVersion is < (version_where_serverId_was_added), this will attempt to add it.
        // If it already exists due to a previous run or manual addition, it might throw an error,
        // which is acceptable if the column is indeed present.
        await db.execute(
          'ALTER TABLE $tableName ADD COLUMN $columnServerId TEXT UNIQUE;',
        );
        print('Successfully added $columnServerId column to $tableName');
      } catch (e) {
        // This might fail if the column already exists, which is fine.
        // Or it might fail for other reasons, which should be logged.
        print(
          'Error adding $columnServerId column to $tableName: $e. It might already exist.',
        );
      }
    }
  }

  Future<void> insertEmotion(EmotionRecord emotion) async {
    final String recordId = emotion.id ?? _uuid.v4();
    DateTime now = DateTime.now();
    await this.db.insert(
      tableName,
      emotion
          .copyWith(
            id: recordId,
            updatedAt: now,
            syncStatus: SyncStatus.created,
          )
          .toMap(), // Changed to SyncStatus.created
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateEmotion(EmotionRecord emotion) async {
    DateTime now = DateTime.now();
    SyncStatus newSyncStatus = emotion.syncStatus ?? SyncStatus.updated;
    if (emotion.syncStatus == SyncStatus.synced ||
        emotion.syncStatus == SyncStatus.updated) {
      newSyncStatus = SyncStatus.updated;
    }

    if (emotion.isDeleted && emotion.syncStatus != SyncStatus.deleted) {
      newSyncStatus = SyncStatus.deleted;
    }

    await this.db.update(
      tableName,
      emotion.copyWith(updatedAt: now, syncStatus: newSyncStatus).toMap(),
      where: 'id = ?',
      whereArgs: [emotion.id],
    );
  }

  Future<void> deleteEmotion(String id) async {
    final existingEmotion = await getEmotionById(id);
    if (existingEmotion != null) {
      final updatedEmotion = existingEmotion.copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.deleted, // Changed to SyncStatus.deleted
      );
      await updateEmotion(updatedEmotion);
    }
  }

  Future<EmotionRecord?> getEmotionById(String id, {Transaction? txn}) async {
    final dbExecutor = txn ?? this.db;
    return _getEmotionByIdInternal(id, dbExecutor);
  }

  Future<void> applyEmotionSyncChanges({
    required List<EmotionRecord> serverEmotions,
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? this.db;
    if (txn == null && dbExecutor is Database) {
      return dbExecutor.transaction((txnInternal) async {
        // Renamed txn to txnInternal to avoid conflict
        await _applyEmotionSyncChangesInternal(serverEmotions, txnInternal);
      });
    } else if (txn != null) {
      return _applyEmotionSyncChangesInternal(serverEmotions, txn);
    } else {
      print(
        "EmotionDao.applyEmotionSyncChanges: Running without explicit transaction wrapper as txn is null and db is not Database.",
      );
      await _applyEmotionSyncChangesInternal(serverEmotions, dbExecutor);
    }
  }

  Future<void> _applyEmotionSyncChangesInternal(
    List<EmotionRecord> serverEmotions,
    dynamic dbOrTxn,
  ) async {
    final Batch batch =
        (dbOrTxn is Transaction)
            ? dbOrTxn.batch()
            : (dbOrTxn as Database).batch();

    for (final serverEmotion in serverEmotions) {
      EmotionRecord? localEmotion;

      if (serverEmotion.serverId != null) {
        localEmotion = await getEmotionByServerId(
          serverEmotion.serverId!,
          txn: dbOrTxn is Transaction ? dbOrTxn : null,
        );
      }
      if (localEmotion == null && serverEmotion.id != null) {
        localEmotion = await _getEmotionByIdInternal(
          serverEmotion.id!,
          dbOrTxn is Transaction ? dbOrTxn : dbOrTxn as DatabaseExecutor,
        ); // Call internal version
      }

      if (localEmotion != null) {
        if (serverEmotion.isDeleted) {
          batch.delete(
            tableName,
            where: 'id = ?',
            whereArgs: [localEmotion.id],
          );
        } else {
          final updateMap =
              serverEmotion
                  .copyWith(
                    id: localEmotion.id,
                    syncStatus: SyncStatus.synced,
                    lastSynced: serverEmotion.updatedAt ?? DateTime.now(),
                  )
                  .toMap();
          batch.update(
            tableName,
            updateMap,
            where: 'id = ?',
            whereArgs: [localEmotion.id],
          );
        }
      } else if (!serverEmotion.isDeleted) {
        final newEmotionMap =
            serverEmotion
                .copyWith(
                  id: serverEmotion.id ?? _uuid.v4(),
                  syncStatus: SyncStatus.synced,
                  lastSynced: serverEmotion.updatedAt ?? DateTime.now(),
                )
                .toMap();
        batch.insert(
          tableName,
          newEmotionMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    await batch.commit(noResult: true);
  }

  // Renamed original getEmotionById to _getEmotionByIdInternal to avoid conflict
  // and to make it clear it's used internally with specific executor context.
  Future<EmotionRecord?> _getEmotionByIdInternal(
    String id,
    DatabaseExecutor dbExecutor,
  ) async {
    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where: 'id = ? AND (isDeleted = 0 OR isDeleted IS NULL)',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return EmotionRecord.fromMap(maps.first);
    }
    return null;
  }

  // New method: Get Emotion by Server ID
  Future<EmotionRecord?> getEmotionByServerId(
    String serverId, {
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? this.db;
    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where: '$columnServerId = ? AND (isDeleted = 0 OR isDeleted IS NULL)',
      whereArgs: [serverId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return EmotionRecord.fromMap(maps.first);
    }
    return null;
  }

  // New method: Get Emotion by Client Temp ID (which is the local 'id')
  Future<EmotionRecord?> getEmotionByClientTempId(
    String clientTempId, {
    Transaction? txn,
  }) async {
    return getEmotionById(
      clientTempId,
      txn: txn,
    ); // Delegates to the updated getEmotionById
  }

  Future<List<EmotionRecord>> getEmotionsForDate(String date) async {
    // Renamed from getEmotionsByDate
    final List<Map<String, dynamic>> maps = await this.db.query(
      tableName,
      where: 'date = ? AND (isDeleted = 0 OR isDeleted IS NULL)',
      whereArgs: [date],
    );
    return List.generate(maps.length, (i) {
      return EmotionRecord.fromMap(maps[i]);
    });
  }

  Future<List<EmotionRecord>> getAllEmotions() async {
    final List<Map<String, dynamic>> maps = await this.db.query(
      tableName,
      where: 'isDeleted = 0 OR isDeleted IS NULL',
    );
    return List.generate(maps.length, (i) {
      return EmotionRecord.fromMap(maps[i]);
    });
  }

  Future<void> markEmotionsAsSynced(
    List<String> clientTempIds, // Changed from ids
    DateTime syncTimestamp, {
    Map<String, String>? serverIds, // Added serverIds
    Transaction? txn, // Added transaction parameter
  }) async {
    if (clientTempIds.isEmpty) {
      return;
    }

    final dbExecutor = txn ?? this.db; // Use transaction if provided
    final batch = dbExecutor.batch();

    for (String clientTempId in clientTempIds) {
      final String? serverId = serverIds?[clientTempId];

      Map<String, dynamic> updateData = {
        'syncStatus': SyncStatus.synced.name,
        'lastSynced': syncTimestamp.toIso8601String(),
        'updatedAt': syncTimestamp.toIso8601String(),
      };

      if (serverId != null) {
        updateData[columnServerId] = serverId;
      }

      batch.update(
        tableName,
        updateData,
        where: 'id = ?', // Assuming clientTempId is the 'id'
        whereArgs: [clientTempId],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<EmotionRecord>> getUnsyncedEmotions({
    DateTime? lastSyncTimestamp,
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? this.db; // Use transaction if provided
    String whereClause =
        'syncStatus != ? AND (isDeleted = 0 OR isDeleted IS NULL)';
    List<dynamic> whereArgs = [SyncStatus.synced.name];

    if (lastSyncTimestamp != null) {
      whereClause += ' AND updatedAt > ?';
      whereArgs.add(lastSyncTimestamp.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return List.generate(maps.length, (i) {
      return EmotionRecord.fromMap(maps[i]);
    });
  }

  Future<List<EmotionRecord>> getDeletedAndUnsyncedEmotions({
    DateTime? lastSyncTimestamp,
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? this.db; // Use transaction if provided
    String whereClause =
        'isDeleted = 1 AND (syncStatus IS NULL OR (syncStatus != ? AND syncStatus != ?))';
    List<dynamic> whereArgs = [SyncStatus.synced.name, 'deleted_synced'];

    if (lastSyncTimestamp != null) {
      whereClause += ' AND updatedAt > ?';
      whereArgs.add(lastSyncTimestamp.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return List.generate(maps.length, (i) {
      return EmotionRecord.fromMap(maps[i]);
    });
  }

  Future<void> saveEmotion(EmotionRecord emotion) async {
    final existing = await getEmotionForHour(emotion.date, emotion.hour);
    if (existing != null) {
      SyncStatus newSyncStatus = existing.syncStatus ?? SyncStatus.updated;
      if (existing.syncStatus == SyncStatus.synced) {
        newSyncStatus = SyncStatus.updated;
      }
      await updateEmotion(
        emotion.copyWith(id: existing.id, syncStatus: newSyncStatus),
      );
    } else {
      await insertEmotion(emotion.copyWith(syncStatus: SyncStatus.created));
    }
  }

  Future<EmotionRecord?> getEmotionForHour(String date, int hour) async {
    // Renamed from getEmotionByDateAndHour
    final List<Map<String, dynamic>> maps = await this.db.query(
      tableName,
      where: 'date = ? AND hour = ? AND (isDeleted = 0 OR isDeleted IS NULL)',
      whereArgs: [date, hour],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return EmotionRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<void> clearAllData() async {
    await this.db.delete(tableName);
  }

  Future<bool> hasUnsyncedChanges({DateTime? lastSyncTimestamp}) async {
    String query =
        'SELECT COUNT(*) FROM $tableName WHERE syncStatus IS NOT NULL AND syncStatus != ? AND syncStatus != ?';
    List<dynamic> args = [SyncStatus.synced.name, 'deleted_synced'];

    if (lastSyncTimestamp != null) {
      query += ' AND updatedAt > ?';
      args.add(lastSyncTimestamp.toIso8601String());
    }

    final unsyncedCount = Sqflite.firstIntValue(await db.rawQuery(query, args));
    return (unsyncedCount ?? 0) > 0;
  }
}
