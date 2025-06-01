import 'package:sqflite/sqflite.dart';
import 'package:recap_today/model/app_usage_model.dart';
import 'package:uuid/uuid.dart';
import 'package:recap_today/model/sync_status.dart';

class AppUsageDao {
  final Database db;

  AppUsageDao(this.db);

  static const String tableName = 'app_usage';
  // Column constants
  static const String columnId = 'id';
  static const String columnPackageName = 'packageName';
  static const String columnAppName = 'appName';
  static const String columnUsageTimeInMillis = 'usageTimeInMillis';
  static const String columnDate = 'date';
  static const String columnAppIconPath = 'appIconPath';
  static const String columnLastSynced =
      'lastSynced'; // Kept for potential direct use, though updatedAt is primary for sync logic
  static const String columnIsDeleted = 'isDeleted';
  static const String columnClientTempId = 'clientTempId';
  static const String columnServerId = 'serverId';
  static const String columnSyncStatus = 'syncStatus';
  static const String columnUpdatedAt = 'updatedAt';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnPackageName TEXT NOT NULL,
        $columnAppName TEXT NOT NULL,
        $columnUsageTimeInMillis INTEGER NOT NULL,
        $columnDate TEXT NOT NULL,
        $columnAppIconPath TEXT,
        $columnLastSynced INTEGER, 
        $columnIsDeleted INTEGER NOT NULL DEFAULT 0,
        $columnClientTempId TEXT UNIQUE,
        $columnServerId TEXT UNIQUE,
        $columnSyncStatus TEXT,
        $columnUpdatedAt INTEGER
      )
    ''');
  }

  static Future<void> upgradeTable(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 18) {
      await _addColumnIfNotExists(
        db,
        tableName,
        columnClientTempId,
        'TEXT UNIQUE',
      );
      await _addColumnIfNotExists(db, tableName, columnServerId, 'TEXT UNIQUE');
      await _addColumnIfNotExists(db, tableName, columnSyncStatus, 'TEXT');
      await _addColumnIfNotExists(db, tableName, columnUpdatedAt, 'INTEGER');
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

  Future<String> insertAppUsage(AppUsageModel item, {Transaction? txn}) async {
    final dbExecutor = txn ?? db;
    String idToInsert = item.id ?? Uuid().v4();
    String? clientTempIdToInsert = item.clientTempId;
    if (clientTempIdToInsert == null && item.serverId == null) {
      clientTempIdToInsert =
          'client_appusage_${DateTime.now().millisecondsSinceEpoch}_${item.hashCode}';
    }

    AppUsageModel itemToSave = item.copyWith(
      id: idToInsert,
      clientTempId: clientTempIdToInsert,
      syncStatus: SyncStatus.created.name,
      updatedAt: DateTime.now(),
    );

    await dbExecutor.insert(
      tableName,
      itemToSave.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return idToInsert;
  }

  Future<List<AppUsageModel>> getAllAppUsages({Transaction? txn}) async {
    final dbExecutor = txn ?? db;
    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where: '$columnIsDeleted = 0',
    );
    return List.generate(maps.length, (i) {
      return AppUsageModel.fromJson(maps[i]);
    });
  }

  Future<AppUsageModel?> getAppUsageById(String id, {Transaction? txn}) async {
    final dbExecutor = txn ?? db;
    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where: '$columnId = ? AND $columnIsDeleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return AppUsageModel.fromJson(maps.first);
    }
    return null;
  }

  Future<AppUsageModel?> getAppUsageByServerId(
    String serverId, {
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where: '$columnServerId = ? AND $columnIsDeleted = 0',
      whereArgs: [serverId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return AppUsageModel.fromJson(maps.first);
    }
    return null;
  }

  Future<AppUsageModel?> getAppUsageByClientTempId(
    String clientTempId, {
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where: '$columnClientTempId = ? AND $columnIsDeleted = 0',
      whereArgs: [clientTempId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return AppUsageModel.fromJson(maps.first);
    }
    return null;
  }

  Future<void> updateAppUsage(AppUsageModel item, {Transaction? txn}) async {
    final dbExecutor = txn ?? db;
    AppUsageModel itemToSave = item.copyWith(
      syncStatus:
          item.syncStatus == SyncStatus.created.name ||
                  item.syncStatus == SyncStatus.synced.name
              ? SyncStatus.updated.name
              : item.syncStatus, // Preserve if e.g. 'deleted'
      updatedAt: DateTime.now(),
    );
    await dbExecutor.update(
      tableName,
      itemToSave.toJson(),
      where: '$columnId = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteAppUsage(String id, {Transaction? txn}) async {
    final dbExecutor = txn ?? db;
    // Soft delete
    final item = await getAppUsageById(id, txn: txn);
    if (item != null) {
      AppUsageModel itemToSave = item.copyWith(
        isDeleted: true,
        syncStatus: SyncStatus.deleted.name,
        updatedAt: DateTime.now(),
      );
      await dbExecutor.update(
        tableName,
        itemToSave.toJson(),
        where: '$columnId = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> hardDeleteAppUsage(String id, {Transaction? txn}) async {
    final dbExecutor = txn ?? db;
    await dbExecutor.delete(tableName, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<void> deleteAppUsagesByDate(String date, {Transaction? txn}) async {
    final dbExecutor = txn ?? db;
    final items = await dbExecutor.query(
      tableName,
      where: '$columnDate = ? AND $columnIsDeleted = 0',
      whereArgs: [date],
    );
    final batch = dbExecutor.batch();
    for (var map in items) {
      final item = AppUsageModel.fromJson(map);
      AppUsageModel itemToSave = item.copyWith(
        isDeleted: true,
        syncStatus: SyncStatus.deleted.name,
        updatedAt: DateTime.now(),
      );
      batch.update(
        tableName,
        itemToSave.toJson(),
        where: '$columnId = ?',
        whereArgs: [item.id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertAppUsages(
    List<AppUsageModel> items, {
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    final batch = dbExecutor.batch();
    for (var item in items) {
      String idToInsert = item.id ?? Uuid().v4();
      String? clientTempIdToInsert = item.clientTempId;
      if (clientTempIdToInsert == null && item.serverId == null) {
        clientTempIdToInsert =
            'client_appusage_${DateTime.now().millisecondsSinceEpoch}_${item.hashCode}';
      }
      AppUsageModel itemWithDetails = item.copyWith(
        id: idToInsert,
        clientTempId: clientTempIdToInsert,
        syncStatus: SyncStatus.created.name,
        updatedAt: DateTime.now(),
      );
      batch.insert(
        tableName,
        itemWithDetails.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAllAppUsages({Transaction? txn}) async {
    final dbExecutor = txn ?? db;
    final items = await getAllAppUsages(txn: txn); // Gets non-deleted items
    final batch = dbExecutor.batch();
    for (var item in items) {
      AppUsageModel itemToSave = item.copyWith(
        isDeleted: true,
        syncStatus: SyncStatus.deleted.name,
        updatedAt: DateTime.now(),
      );
      batch.update(
        tableName,
        itemToSave.toJson(),
        where: '$columnId = ?',
        whereArgs: [item.id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<AppUsageSummary?> getAppUsageSummaryForDate(
    String date, {
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where: '$columnDate = ? AND $columnIsDeleted = 0',
      whereArgs: [date],
      orderBy: '$columnUsageTimeInMillis DESC',
    );

    if (maps.isEmpty) {
      return null;
    }

    final appUsages = maps.map((map) => AppUsageModel.fromJson(map)).toList();

    final totalUsage = appUsages.fold<int>(
      0,
      (sum, item) => sum + item.usageTimeInMillis,
    );

    // Take top 3 or fewer if not enough items
    final topApps = appUsages.take(3).toList();

    return AppUsageSummary(
      date: date,
      totalUsageTimeInMillis: totalUsage,
      topApps: topApps,
    );
  }

  Future<int> getAppUsageCountForDate(String date, {Transaction? txn}) async {
    final dbExecutor = txn ?? db;
    final List<Map<String, dynamic>> result = await dbExecutor.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE $columnDate = ? AND $columnIsDeleted = 0',
      [date],
    );
    int count = Sqflite.firstIntValue(result) ?? 0;
    return count;
  }

  Future<List<AppUsageModel>> getUnsyncedAppUsages({
    DateTime? lastSyncTimestamp,
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    // Get records that are created, updated, or deleted (and not yet synced as deleted)
    String whereClause =
        '($columnSyncStatus = ? OR $columnSyncStatus = ? OR $columnSyncStatus = ?)';
    List<dynamic> whereArgs = [
      SyncStatus.created.name,
      SyncStatus.updated.name,
      SyncStatus.deleted.name,
    ];

    if (lastSyncTimestamp != null) {
      whereClause += ' AND $columnUpdatedAt > ?';
      whereArgs.add(lastSyncTimestamp.millisecondsSinceEpoch);
    }

    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return maps.map((map) => AppUsageModel.fromJson(map)).toList();
  }

  Future<void> markAppUsagesAsSynced(
    List<String> clientTempIds,
    DateTime syncTimestamp, {
    Map<String, String>?
    serverIds, // Changed from List<String>? to Map<String, String>?
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    if (clientTempIds.isEmpty) return;

    final batch = dbExecutor.batch();
    final syncTimeEpoch = syncTimestamp.millisecondsSinceEpoch;

    for (String clientTempId in clientTempIds) {
      final Map<String, Object?> dataToUpdate = {
        columnSyncStatus: SyncStatus.synced.name,
        columnUpdatedAt: syncTimeEpoch,
        columnLastSynced:
            syncTimeEpoch, // Also update legacy lastSynced for consistency
      };

      if (serverIds != null && serverIds.containsKey(clientTempId)) {
        dataToUpdate[columnServerId] = serverIds[clientTempId];
      }

      // This will update both non-deleted and soft-deleted items that match the clientTempId
      // If an item was soft-deleted (isDeleted=1, syncStatus=deleted),
      // it will now become (isDeleted=1, syncStatus=synced)
      batch.update(
        tableName,
        dataToUpdate,
        where: '$columnClientTempId = ?',
        whereArgs: [clientTempId],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> applyAppUsageSyncChanges(
    List<AppUsageModel> serverItems, {
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    final batch = dbExecutor.batch();

    for (final serverItem in serverItems) {
      AppUsageModel? localItem;
      if (serverItem.serverId != null) {
        localItem = await getAppUsageByServerId(serverItem.serverId!, txn: txn);
      }
      if (localItem == null && serverItem.clientTempId != null) {
        localItem = await getAppUsageByClientTempId(
          serverItem.clientTempId!,
          txn: txn,
        );
      }

      final DateTime effectiveUpdatedAt =
          serverItem.updatedAt ?? DateTime.now();

      final itemToSave = serverItem.copyWith(
        syncStatus: SyncStatus.synced.name,
        updatedAt: effectiveUpdatedAt,
        lastSynced: effectiveUpdatedAt, // Corrected: assign DateTime, not int
      );

      if (localItem != null && localItem.id != null) {
        // Update existing
        // If server item is marked deleted, update local to be deleted and synced.
        // If server item is not deleted, update local with server data.
        batch.update(
          tableName,
          itemToSave
              .copyWith(
                id: localItem.id, // Keep local ID
                clientTempId:
                    localItem.clientTempId ??
                    serverItem
                        .clientTempId, // Preserve local clientTempId if server's is null
              )
              .toJson(),
          where: '$columnId = ?',
          whereArgs: [localItem.id],
        );
      } else {
        // Insert new, only if not marked as deleted by server
        if (!itemToSave.isDeleted) {
          final newId = itemToSave.id ?? Uuid().v4();
          batch.insert(
            tableName,
            itemToSave
                .copyWith(
                  id: newId, // Ensure local ID
                  // clientTempId can be from serverItem or null if server doesn't send it for new items
                )
                .toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        // If serverItem is deleted and not found locally, do nothing.
      }
    }
    await batch.commit(noResult: true);
  }

  Future<bool> hasUnsyncedAppUsageChanges({
    DateTime? lastSyncTimestamp,
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    // Checks for items that are 'created', 'updated', or 'deleted'
    String query =
        'SELECT COUNT(*) FROM $tableName WHERE ($columnSyncStatus = ? OR $columnSyncStatus = ? OR $columnSyncStatus = ?)';
    List<dynamic> args = [
      SyncStatus.created.name,
      SyncStatus.updated.name,
      SyncStatus.deleted.name,
    ];

    if (lastSyncTimestamp != null) {
      query += ' AND $columnUpdatedAt > ?';
      args.add(lastSyncTimestamp.millisecondsSinceEpoch);
    }

    final count = Sqflite.firstIntValue(await dbExecutor.rawQuery(query, args));
    return (count ?? 0) > 0;
  }
}
