import 'package:sqflite/sqflite.dart';
import 'package:recap_today/model/schedule_item.dart'
    as model_schedule_item; // Aliased import
import 'package:recap_today/model/sync_status.dart';

class ScheduleDao {
  final Database _db;
  static const String tableSchedule = 'schedule_items';

  ScheduleDao(this._db);

  // DDL Methods
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableSchedule (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL, // Changed from title to text to match model
        subText TEXT,
        dayOfWeek INTEGER,
        selectedDate TEXT,
        isRoutine INTEGER NOT NULL DEFAULT 0,
        startTimeHour INTEGER NOT NULL, // Changed from startTime TEXT
        startTimeMinute INTEGER NOT NULL, // Changed from startTime TEXT
        endTimeHour INTEGER NOT NULL, // Changed from endTime TEXT
        endTimeMinute INTEGER NOT NULL, // Changed from endTime TEXT
        colorValue INTEGER,
        hasAlarm INTEGER DEFAULT 0,
        alarmOffsetInMinutes INTEGER,
        
        -- Sync related fields --
        clientTempId TEXT,
        serverId TEXT,
        syncStatus TEXT NOT NULL DEFAULT '${SyncStatus.created.name}',
        createdAt TEXT, // Added
        updatedAt TEXT,
        lastSynced TEXT, // Added

        -- Deprecated fields (kept for migration, but not actively used by new model logic) --
        isSynced INTEGER NOT NULL DEFAULT 0, 
        lastModified TEXT,

        -- Fields that might have been missed or were unclear in previous DDLs --
        -- 'date' and 'isCompleted' from original DDL, ensure they are handled or removed if not needed
        -- For now, assume 'selectedDate' covers 'date' and 'isCompleted' is not part of ScheduleItem
        notificationId INTEGER -- Kept from original DDL, model doesn't have it explicitly
      )
    ''');
  }

  static Future<void> upgradeTable(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Example: Version 16 introduces new sync fields for ScheduleDao
    if (oldVersion < 16) {
      // Assuming 16 is the version these fields are formally added
      await _addColumnIfNotExists(db, tableSchedule, 'clientTempId', 'TEXT');
      await _addColumnIfNotExists(
        db,
        tableSchedule,
        'syncStatus',
        'TEXT NOT NULL DEFAULT \'${SyncStatus.created.name}\'',
      );
      await _addColumnIfNotExists(
        db,
        tableSchedule,
        'createdAt',
        'TEXT',
      ); // Added
      await _addColumnIfNotExists(db, tableSchedule, 'updatedAt', 'TEXT');
      await _addColumnIfNotExists(
        db,
        tableSchedule,
        'lastSynced',
        'TEXT',
      ); // Added

      await _addColumnIfNotExists(
        db,
        tableSchedule,
        'text',
        'TEXT NOT NULL DEFAULT \''
            '',
      );
      await _addColumnIfNotExists(db, tableSchedule, 'subText', 'TEXT');
      await _addColumnIfNotExists(
        db,
        tableSchedule,
        'startTimeHour',
        'INTEGER',
      );
      await _addColumnIfNotExists(
        db,
        tableSchedule,
        'startTimeMinute',
        'INTEGER',
      );
      await _addColumnIfNotExists(db, tableSchedule, 'endTimeHour', 'INTEGER');
      await _addColumnIfNotExists(
        db,
        tableSchedule,
        'endTimeMinute',
        'INTEGER',
      );
      await _addColumnIfNotExists(db, tableSchedule, 'colorValue', 'INTEGER');
      await _addColumnIfNotExists(
        db,
        tableSchedule,
        'hasAlarm',
        'INTEGER DEFAULT 0',
      );
      await _addColumnIfNotExists(
        db,
        tableSchedule,
        'alarmOffsetInMinutes',
        'INTEGER',
      );
    }
    // This specific upgrade logic is tied to the DatabaseHelper's versioning.
    // For ScheduleDao, we ensure all columns exist if upgrading from a version before they were added.
    // The version `10` is based on the last known version in DatabaseHelper where these columns were managed.
    // IMPORTANT: The order of these checks matters. If < 10 also implies < 16, the < 16 block should run first or handle all cases.
    // For simplicity, assuming distinct version blocks. If there's overlap, logic needs to be more robust.
    if (oldVersion < 10) {
      await _addColumnIfNotExists(
        db,
        tableSchedule,
        'text',
        'TEXT NOT NULL DEFAULT \''
            '',
      );
      await _addColumnIfNotExists(
        db,
        tableSchedule,
        'isRoutine',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _addColumnIfNotExists(db, tableSchedule, 'dayOfWeek', 'INTEGER');
      await _addColumnIfNotExists(db, tableSchedule, 'selectedDate', 'TEXT');
      await _addColumnIfNotExists(db, tableSchedule, 'lastModified', 'TEXT');
      await _addColumnIfNotExists(
        db,
        tableSchedule,
        'isSynced',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _addColumnIfNotExists(db, tableSchedule, 'serverId', 'TEXT');
      await _addColumnIfNotExists(db, tableSchedule, 'subText', 'TEXT');
      await _addColumnIfNotExists(
        db,
        tableSchedule,
        'startTimeHour',
        'INTEGER',
      );
      await _addColumnIfNotExists(
        db,
        tableSchedule,
        'startTimeMinute',
        'INTEGER',
      );
      await _addColumnIfNotExists(db, tableSchedule, 'endTimeHour', 'INTEGER');
      await _addColumnIfNotExists(
        db,
        tableSchedule,
        'endTimeMinute',
        'INTEGER',
      );
      await _addColumnIfNotExists(db, tableSchedule, 'colorValue', 'INTEGER');
      await _addColumnIfNotExists(
        db,
        tableSchedule,
        'hasAlarm',
        'INTEGER DEFAULT 0',
      );
      await _addColumnIfNotExists(
        db,
        tableSchedule,
        'alarmOffsetInMinutes',
        'INTEGER',
      );
    }
  }

  static Future<void> _addColumnIfNotExists(
    Database db,
    String tableName,
    String columnName,
    String columnType,
  ) async {
    List<dynamic> result = await db.rawQuery('PRAGMA table_info($tableName)');
    bool columnExists = result.any((column) => column['name'] == columnName);
    if (!columnExists) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnName $columnType',
      );
    }
  }

  // CRUD Methods
  Future<int> insertScheduleItem(
    model_schedule_item.ScheduleItem item, {
    Transaction? txn,
  }) async {
    // Added txn, return type Future<int>
    final dbClient = txn ?? _db;
    try {
      // Ensure updatedAt is set before saving
      final itemToSave = item.copyWith(
        updatedAt: DateTime.now(),
        // Ensure clientTempId is set if not already
        clientTempId: item.clientTempId ?? item.id,
      );
      // The insert method in sqflite returns the row ID of the last inserted row.
      // For tables with a TEXT PRIMARY KEY, this might not be directly useful as an integer ID.
      // However, the task requires Future<int>. We'll return 1 for success, 0 for failure,
      // as the actual string ID is part of the item object.
      // A more robust solution might involve ensuring the primary key is an INTEGER AUTOINCREMENT
      // if an integer ID is strictly needed from the insert operation itself.
      // For now, adhering to the return type.
      await dbClient.insert(
        tableSchedule,
        itemToSave.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return 1; // Indicate success
    } catch (e) {
      print('Error inserting schedule item: $e');
      // Return 0 or throw, depending on how AbstractDatabase expects to handle errors.
      // For now, returning 0 to satisfy Future<int> and indicate failure.
      return 0;
    }
  }

  Future<List<model_schedule_item.ScheduleItem>> getScheduleItems({
    Transaction? txn,
  }) async {
    // Added txn
    final dbClient = txn ?? _db;
    try {
      final List<Map<String, dynamic>> maps = await dbClient.query(
        tableSchedule,
      );
      return List.generate(maps.length, (i) {
        return model_schedule_item.ScheduleItem.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting schedule items: $e');
      return [];
    }
  }

  Future<model_schedule_item.ScheduleItem?> getScheduleItemById(
    String id, {
    Transaction? txn,
  }) async {
    // Added txn
    final dbClient = txn ?? _db;
    try {
      final List<Map<String, dynamic>> maps = await dbClient.query(
        tableSchedule,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return model_schedule_item.ScheduleItem.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting schedule item by ID: $e');
      return null;
    }
  }

  Future<model_schedule_item.ScheduleItem?> getScheduleItemByServerId(
    String serverId, {
    Transaction? txn,
  }) async {
    // Added txn
    final dbClient = txn ?? _db;
    if (serverId.isEmpty) return null;
    try {
      final List<Map<String, dynamic>> maps = await dbClient.query(
        tableSchedule,
        where: 'serverId = ?',
        whereArgs: [serverId],
        limit: 1, // Ensure only one record is returned
      );
      if (maps.isNotEmpty) {
        return model_schedule_item.ScheduleItem.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting schedule item by server ID: $e');
      return null;
    }
  }

  Future<model_schedule_item.ScheduleItem?> getScheduleItemByClientTempId(
    String clientTempId, {
    Transaction? txn,
  }) async {
    // Added txn
    final dbClient = txn ?? _db;
    if (clientTempId.isEmpty) return null;
    try {
      final List<Map<String, dynamic>> maps = await dbClient.query(
        tableSchedule,
        where: 'clientTempId = ?',
        whereArgs: [clientTempId],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return model_schedule_item.ScheduleItem.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting schedule item by clientTempId: $e');
      return null;
    }
  }

  Future<int> updateScheduleItem(
    model_schedule_item.ScheduleItem item, {
    Transaction? txn,
  }) async {
    // Added txn
    final dbClient = txn ?? _db;
    try {
      final itemToSave = item.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.updated,
      );
      return await dbClient.update(
        tableSchedule,
        itemToSave.toMap(),
        where: 'id = ?',
        whereArgs: [itemToSave.id],
      );
    } catch (e) {
      print('Error updating schedule item: $e');
      rethrow;
    }
  }

  Future<int> deleteScheduleItem(String id, {Transaction? txn}) async {
    // Added txn
    final dbClient = txn ?? _db;
    try {
      final existingItem = await getScheduleItemById(id, txn: txn);
      if (existingItem != null) {
        final deletedItem = existingItem.copyWith(
          syncStatus: SyncStatus.deleted,
          updatedAt: DateTime.now(),
        );
        return await dbClient.update(
          // Use update for soft delete
          tableSchedule,
          deletedItem.toMap(),
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      return 0; // Item not found
    } catch (e) {
      print('Error soft deleting schedule item: $e');
      rethrow;
    }
  }

  Future<int> hardDeleteScheduleItem(String id, {Transaction? txn}) async {
    // Added txn
    final dbClient = txn ?? _db;
    try {
      return await dbClient.delete(
        tableSchedule,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error hard deleting schedule item: $e');
      rethrow;
    }
  }

  // Additional methods from DatabaseHelper that might be relevant for ScheduleDao
  // These are not strictly CRUD but are specific to schedule items

  Future<List<model_schedule_item.ScheduleItem>> getSchedulesByDate(
    DateTime date, {
    Transaction? txn,
  }) async {
    // Added txn
    final dbClient = txn ?? _db;
    try {
      final dateStr = date.toIso8601String().substring(0, 10);
      final result = await dbClient.query(
        tableSchedule,
        where:
            'selectedDate = ? AND isRoutine = 0 AND (syncStatus IS NULL OR syncStatus != ?)',
        whereArgs: [
          dateStr,
          SyncStatus.deleted.name,
        ], // Filter out soft-deleted items
      );
      return result
          .map((map) => model_schedule_item.ScheduleItem.fromMap(map))
          .toList();
    } catch (e) {
      print('Error getting schedules by date: $e');
      return [];
    }
  }

  Future<List<model_schedule_item.ScheduleItem>> getSchedulesByDateRange(
    DateTime start,
    DateTime end, {
    Transaction? txn, // Added txn
  }) async {
    final dbClient = txn ?? _db;
    try {
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);
      final result = await dbClient.query(
        tableSchedule,
        where:
            'selectedDate >= ? AND selectedDate <= ? AND isRoutine = 0 AND (syncStatus IS NULL OR syncStatus != ?)',
        whereArgs: [
          startStr,
          endStr,
          SyncStatus.deleted.name,
        ], // Filter out soft-deleted items
      );
      return result
          .map((map) => model_schedule_item.ScheduleItem.fromMap(map))
          .toList();
    } catch (e) {
      print('Error getting schedules by date range: $e');
      return [];
    }
  }

  Future<int> deleteScheduleItemsInRange(
    DateTime start,
    DateTime end, {
    Transaction? txn,
  }) async {
    // Added txn
    final dbClient = txn ?? _db;
    try {
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);

      return await dbClient.delete(
        tableSchedule,
        // Assuming selectedDate is the correct field for range deletion of non-routine items.
        // If date field should be used for all items, adjust accordingly.
        where: 'selectedDate >= ? AND selectedDate <= ? AND isRoutine = 0',
        whereArgs: [startStr, endStr],
      );
    } catch (e) {
      print('Error deleting schedule items by date range: $e');
      rethrow;
    }
  }

  Future<void> saveScheduleItems(
    List<model_schedule_item.ScheduleItem> items, {
    Transaction? txn,
  }) async {
    // Added txn
    try {
      if (txn != null) {
        // If a transaction is provided, use it directly for batch
        Batch batch = txn.batch();
        for (final item in items) {
          final itemToSave = item.copyWith(
            updatedAt: DateTime.now(),
            clientTempId: item.clientTempId ?? item.id,
          );
          batch.insert(
            tableSchedule,
            itemToSave.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      } else {
        // Otherwise, create a new transaction on _db
        await _db.transaction((txnDb) async {
          Batch batch = txnDb.batch();
          for (final item in items) {
            final itemToSave = item.copyWith(
              updatedAt: DateTime.now(),
              clientTempId: item.clientTempId ?? item.id,
            );
            batch.insert(
              tableSchedule,
              itemToSave.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
        });
      }
    } catch (e) {
      print('Error batch saving schedule items: $e');
      rethrow;
    }
  }

  Future<List<model_schedule_item.ScheduleItem>> getRoutineScheduleItems({
    Transaction? txn,
  }) async {
    // Added txn
    final dbClient = txn ?? _db;
    try {
      final result = await dbClient.query(
        tableSchedule,
        where: 'isRoutine = ?',
        whereArgs: [1],
      );
      return result
          .map((map) => model_schedule_item.ScheduleItem.fromMap(map))
          .toList();
    } catch (e) {
      print('Error getting routine schedule items: $e');
      return [];
    }
  }

  Future<int> deleteAllScheduleItems({Transaction? txn}) async {
    // Added txn
    final dbClient = txn ?? _db;
    try {
      return await dbClient.delete(tableSchedule);
    } catch (e) {
      print('Error deleting all schedule items: $e');
      rethrow;
    }
  }

  Future<List<DateTime>> getScheduleDatesForMonth(
    int year,
    int month, {
    Transaction? txn,
  }) async {
    // Added txn
    final dbClient = txn ?? _db;
    try {
      final String monthStr = month.toString().padLeft(2, '0');
      final String yearStr = year.toString();
      final List<Map<String, dynamic>> maps = await dbClient.query(
        tableSchedule,
        columns: ['selectedDate'], // Only select the selectedDate column
        distinct: true, // Get unique dates
        where:
            'strftime(\'%Y-%m\', selectedDate) = ? AND (syncStatus IS NULL OR syncStatus != ?)', // Filter by year and month, and ensure not deleted
        whereArgs: ['${yearStr}-${monthStr}', SyncStatus.deleted.name],
      );
      return maps
          .map((map) => map['selectedDate'] as String?)
          .where(
            (dateStr) => dateStr != null && dateStr.isNotEmpty,
          ) // Filter out null/empty strings
          .map((dateStr) => DateTime.parse(dateStr!))
          .toList();
    } catch (e) {
      print('Error getting schedule dates for month: $e');
      return [];
    }
  }

  Future<bool> hasSchedule({Transaction? txn}) async {
    // Added txn
    final dbClient = txn ?? _db;
    try {
      final result = await dbClient.rawQuery(
        'SELECT COUNT(*) FROM $tableSchedule',
      );
      int? count = Sqflite.firstIntValue(result);
      return count != null && count > 0;
    } catch (e) {
      print('Error checking for schedules: $e');
      return false; // Or rethrow, depending on desired error handling
    }
  }

  // Sync related methods
  Future<List<model_schedule_item.ScheduleItem>> getUnsyncedScheduleItems({
    // Renamed from getUnsyncedSchedules
    DateTime? lastSyncTimestamp,
    Transaction? txn, // Added txn
  }) async {
    final dbClient = txn ?? _db;
    try {
      String whereClause = 'syncStatus != ?';
      List<dynamic> whereArgs = [SyncStatus.synced.name];

      if (lastSyncTimestamp != null) {
        // Fetch items that are:
        // 1. Created locally (syncStatus = created)
        // 2. Updated locally AFTER last sync (syncStatus = updated AND updatedAt > lastSyncTimestamp)
        // 3. Deleted locally (syncStatus = deleted)
        // We need to be careful with 'updatedAt' for 'created' and 'deleted' items.
        // For 'created', its 'updatedAt' is its creation time.
        // For 'deleted', its 'updatedAt' is its deletion time.
        // The goal is to get items that the server doesn't know about or has an older version of.
        whereClause =
            '(syncStatus = ? OR syncStatus = ? OR (syncStatus = ? AND updatedAt > ?))';
        whereArgs = [
          SyncStatus.created.name,
          SyncStatus.deleted.name,
          SyncStatus.updated.name,
          lastSyncTimestamp.toIso8601String(),
        ];
      }
      // If no lastSyncTimestamp, fetch all non-synced items (created, updated, deleted)
      // This is covered by the initial whereClause if lastSyncTimestamp is null and the more specific one is not used.

      final List<Map<String, dynamic>> maps = await dbClient.query(
        tableSchedule,
        where: whereClause,
        whereArgs: whereArgs,
      );
      return List.generate(maps.length, (i) {
        return model_schedule_item.ScheduleItem.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting unsynced schedule items: $e');
      return [];
    }
  }

  Future<void> markScheduleItemsAsSynced(
    // New method signature
    List<String> clientTempIds,
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    if (clientTempIds.isEmpty) return;

    try {
      Batch batch = dbClient.batch();
      for (String clientTempId in clientTempIds) {
        String? serverId = serverIds?[clientTempId];
        Map<String, dynamic> updateValues = {
          'syncStatus': SyncStatus.synced.name,
          'lastSynced': syncTimestamp.toIso8601String(),
          'updatedAt':
              syncTimestamp
                  .toIso8601String(), // Also update updatedAt to sync time
        };
        if (serverId != null && serverId.isNotEmpty) {
          updateValues['serverId'] = serverId;
          // Optionally, clear clientTempId if serverId is now the primary identifier
          // updateValues['clientTempId'] = null;
        }
        batch.update(
          tableSchedule,
          updateValues,
          where:
              'clientTempId = ? OR id = ?', // Match by clientTempId or local id if clientTempId was not set
          whereArgs: [clientTempId, clientTempId],
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      print('Error marking schedule items as synced: $e');
      rethrow;
    }
  }

  Future<void> applyScheduleItemSyncChanges(
    // Renamed from applyScheduleSyncChanges, model aliased
    List<model_schedule_item.ScheduleItem> serverItems, {
    Transaction? txn,
  }) async {
    try {
      if (txn != null) {
        // If a transaction is provided, use it directly
        Batch batch = txn.batch();
        for (final serverItem in serverItems) {
          model_schedule_item.ScheduleItem? localItem;

          if (serverItem.serverId != null && serverItem.serverId!.isNotEmpty) {
            localItem = await getScheduleItemByServerId(
              serverItem.serverId!,
              txn: txn,
            );
          }
          if (localItem == null &&
              serverItem.clientTempId != null &&
              serverItem.clientTempId!.isNotEmpty) {
            localItem = await getScheduleItemByClientTempId(
              serverItem.clientTempId!,
              txn: txn,
            );
          }
          if (localItem == null) {
            localItem = await getScheduleItemById(serverItem.id, txn: txn);
          }

          final serverItemMap =
              serverItem
                  .copyWith(
                    syncStatus: SyncStatus.synced,
                    lastSynced: serverItem.updatedAt ?? DateTime.now(),
                  )
                  .toMap();

          if (localItem != null) {
            if (serverItem.syncStatus == SyncStatus.deleted) {
              batch.delete(
                tableSchedule,
                where: 'id = ?',
                whereArgs: [localItem.id],
              );
            } else if ((serverItem.updatedAt ?? DateTime(0)).isAfter(
              localItem.updatedAt ?? DateTime(0),
            )) {
              batch.update(
                tableSchedule,
                serverItemMap,
                where: 'id = ?',
                whereArgs: [localItem.id],
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          } else if (serverItem.syncStatus != SyncStatus.deleted) {
            final itemToInsert = serverItem.copyWith(
              clientTempId: serverItem.clientTempId ?? serverItem.id,
              syncStatus: SyncStatus.synced,
              lastSynced: serverItem.updatedAt ?? DateTime.now(),
            );
            batch.insert(
              tableSchedule,
              itemToInsert.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
        await batch.commit(noResult: true);
      } else {
        // Otherwise, create a new transaction on _db
        await _db.transaction((txnDb) async {
          Batch batch = txnDb.batch();
          for (final serverItem in serverItems) {
            model_schedule_item.ScheduleItem? localItem;

            if (serverItem.serverId != null &&
                serverItem.serverId!.isNotEmpty) {
              localItem = await getScheduleItemByServerId(
                serverItem.serverId!,
                txn: txnDb,
              );
            }
            if (localItem == null &&
                serverItem.clientTempId != null &&
                serverItem.clientTempId!.isNotEmpty) {
              localItem = await getScheduleItemByClientTempId(
                serverItem.clientTempId!,
                txn: txnDb,
              );
            }
            if (localItem == null) {
              localItem = await getScheduleItemById(serverItem.id, txn: txnDb);
            }

            final serverItemMap =
                serverItem
                    .copyWith(
                      syncStatus: SyncStatus.synced,
                      lastSynced: serverItem.updatedAt ?? DateTime.now(),
                    )
                    .toMap();

            if (localItem != null) {
              if (serverItem.syncStatus == SyncStatus.deleted) {
                batch.delete(
                  tableSchedule,
                  where: 'id = ?',
                  whereArgs: [localItem.id],
                );
              } else if ((serverItem.updatedAt ?? DateTime(0)).isAfter(
                localItem.updatedAt ?? DateTime(0),
              )) {
                batch.update(
                  tableSchedule,
                  serverItemMap,
                  where: 'id = ?',
                  whereArgs: [localItem.id],
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            } else if (serverItem.syncStatus != SyncStatus.deleted) {
              final itemToInsert = serverItem.copyWith(
                clientTempId: serverItem.clientTempId ?? serverItem.id,
                syncStatus: SyncStatus.synced,
                lastSynced: serverItem.updatedAt ?? DateTime.now(),
              );
              batch.insert(
                tableSchedule,
                itemToInsert.toMap(),
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
          await batch.commit(noResult: true);
        });
      }
    } catch (e) {
      print('Error applying schedule sync changes: $e');
      rethrow;
    }
  }

  Future<bool> hasUnsyncedChanges({
    DateTime? lastSyncTimestamp,
    Transaction? txn,
  }) async {
    // Added txn
    final dbClient = txn ?? _db;
    // Corrected logic: check for syncStatus created, updated, or deleted.
    // If lastSyncTimestamp is provided, 'updated' items must be newer than it.
    // 'created' and 'deleted' items are always considered unsynced if their status says so.
    try {
      String whereClause;
      List<dynamic> whereArgs;

      if (lastSyncTimestamp != null) {
        whereClause =
            '(syncStatus = ? OR syncStatus = ? OR (syncStatus = ? AND updatedAt > ?))';
        whereArgs = [
          SyncStatus.created.name,
          SyncStatus.deleted.name,
          SyncStatus.updated.name,
          lastSyncTimestamp.toIso8601String(),
        ];
      } else {
        // If no lastSyncTimestamp, any item not 'synced' is an unsynced change.
        whereClause = 'syncStatus != ?';
        whereArgs = [SyncStatus.synced.name];
      }

      final count = Sqflite.firstIntValue(
        await dbClient.rawQuery(
          'SELECT COUNT(*) FROM $tableSchedule WHERE $whereClause',
          whereArgs,
        ),
      );
      return (count ?? 0) > 0;
    } catch (e) {
      print('Error in hasUnsyncedChanges for schedules: $e');
      return false; // Or rethrow, depending on desired error handling
    }
  }

  // Method to import schedules, typically during a sync operation
  Future<void> importSchedules(
    List<Map<String, dynamic>> schedulesData,
    DateTime syncTime, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    try {
      Future<void> performImport(Transaction activeTransaction) async {
        Batch batch = activeTransaction.batch();
        for (final scheduleMap in schedulesData) {
          final serverItem = model_schedule_item.ScheduleItem.fromMap(
            scheduleMap,
          );

          model_schedule_item.ScheduleItem? localItem;

          if (serverItem.serverId != null && serverItem.serverId!.isNotEmpty) {
            localItem = await getScheduleItemByServerId(
              serverItem.serverId!,
              txn: activeTransaction,
            );
          }
          if (localItem == null &&
              serverItem.clientTempId != null &&
              serverItem.clientTempId!.isNotEmpty) {
            localItem = await getScheduleItemByClientTempId(
              serverItem.clientTempId!,
              txn: activeTransaction,
            );
          }
          if (localItem == null &&
              scheduleMap.containsKey('id') &&
              scheduleMap['id'] is String) {
            localItem = await getScheduleItemById(
              scheduleMap['id'] as String,
              txn: activeTransaction,
            );
          }

          final String idForUpsert = localItem?.id ?? serverItem.id;

          final itemToUpsert = serverItem.copyWith(
            id: idForUpsert,
            syncStatus: SyncStatus.synced,
            lastSynced: syncTime,
            updatedAt: syncTime,
            clientTempId:
                serverItem.clientTempId ??
                localItem?.clientTempId ??
                (serverItem.id != serverItem.serverId ? serverItem.id : null),
          );

          if (localItem != null) {
            batch.update(
              tableSchedule,
              itemToUpsert.toMap(),
              where: 'id = ?',
              whereArgs: [localItem.id],
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } else {
            batch.insert(
              tableSchedule,
              itemToUpsert.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
        await batch.commit(noResult: true);
      }

      if (dbClient is Database) {
        await dbClient.transaction(performImport);
      } else if (dbClient is Transaction) {
        await performImport(dbClient);
      } else {
        throw Exception(
          'Unsupported DatabaseExecutor type for transaction in importSchedules',
        );
      }
    } catch (e) {
      print('Error importing schedules in ScheduleDao: $e');
      rethrow;
    }
  }
}
