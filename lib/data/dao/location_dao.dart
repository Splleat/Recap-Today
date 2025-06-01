// filepath: d:\\FlutterProjects\\newclone\\Recap-Today\\lib\\data\\dao\\location_dao.dart
import 'package:sqflite/sqflite.dart';
import 'package:recap_today/model/location_model.dart'; // Will be LocationRecord
import 'package:recap_today/model/sync_status.dart';

class LocationDao {
  static const String tableName = 'location_logs';
  final Database db;

  // Column constants for sync logic
  static const String columnId = 'id';
  static const String columnClientTempId = 'clientTempId';
  static const String columnServerId = 'serverId';
  static const String columnUserId = 'userId';
  static const String columnLatitude = 'latitude';
  static const String columnLongitude = 'longitude';
  static const String columnTimestamp = 'timestamp';
  static const String columnLastSynced = 'lastSynced';
  static const String columnIsDeleted = 'isDeleted';
  static const String columnSyncStatus = 'syncStatus';
  static const String columnUpdatedAt = 'updatedAt';

  LocationDao(this.db);

  Future<void> createTable() async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnClientTempId TEXT UNIQUE,
        $columnServerId TEXT UNIQUE,
        $columnUserId TEXT NOT NULL,
        $columnLatitude REAL NOT NULL,
        $columnLongitude REAL NOT NULL,
        $columnTimestamp TEXT NOT NULL,
        $columnLastSynced TEXT,
        $columnIsDeleted INTEGER NOT NULL DEFAULT 0,
        $columnSyncStatus TEXT,
        $columnUpdatedAt TEXT
      )
    ''');
  }

  Future<void> upgradeTable(int oldVersion, int newVersion) async {
    if (oldVersion < 15) {
      try {
        await db.execute(
          'ALTER TABLE $tableName ADD COLUMN $columnClientTempId TEXT UNIQUE',
        );
        await db.execute(
          'ALTER TABLE $tableName ADD COLUMN $columnServerId TEXT UNIQUE',
        );
        await db.execute(
          'ALTER TABLE $tableName ADD COLUMN $columnSyncStatus TEXT',
        );
        await db.execute(
          'ALTER TABLE $tableName ADD COLUMN $columnUpdatedAt TEXT',
        );
      } catch (e) {
        print(
          'Error adding sync columns to $tableName: $e. They might already exist or another issue occurred.',
        );
      }
      if (oldVersion < 14) {
        // This check should be nested or separate if v15 changes depend on v14
        try {
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN $columnLastSynced TEXT',
          );
        } catch (e) {
          print('Error adding $columnLastSynced (v15 upgrade for <v14): $e');
        }
        try {
          await db.execute(
            'ALTER TABLE $tableName ADD COLUMN $columnIsDeleted INTEGER NOT NULL DEFAULT 0',
          );
        } catch (e) {
          print('Error adding $columnIsDeleted (v15 upgrade for <v14): $e');
        }
      }
    }
  }

  Future<void> insertLocation(LocationRecord record, {Transaction? txn}) async {
    final dbExecutor = txn ?? db;
    final newRecord = record.copyWith(
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.created,
      clientTempId:
          record.serverId == null && record.clientTempId == null
              ? 'client_loc_${DateTime.now().millisecondsSinceEpoch}_${record.hashCode}'
              : record.clientTempId,
      id:
          record.id ??
          'local_loc_${DateTime.now().millisecondsSinceEpoch}_${record.hashCode}',
    );
    await dbExecutor.insert(
      tableName,
      newRecord.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateLocation(LocationRecord record, {Transaction? txn}) async {
    final dbExecutor = txn ?? db;
    final updatedRecord = record.copyWith(
      updatedAt: DateTime.now(),
      syncStatus:
          record.syncStatus == SyncStatus.created ||
                  record.syncStatus ==
                      SyncStatus
                          .synced // if created or already synced, mark as updated
              ? SyncStatus.updated
              : record
                  .syncStatus, // otherwise preserve status (e.g. if it was 'deleted')
    );
    await dbExecutor.update(
      tableName,
      updatedRecord.toMap(),
      where: '$columnId = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> deleteLocationLog(String id, {Transaction? txn}) async {
    final dbExecutor = txn ?? db;
    final existing = await getLocationLogById(id, txn: txn);
    if (existing != null) {
      final updatedRecord = existing.copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.deleted,
      );
      await dbExecutor.update(
        tableName,
        updatedRecord.toMap(),
        where: '$columnId = ?',
        whereArgs: [id],
      );
    }
  }

  Future<LocationRecord?> getLocationLogById(
    String id, {
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where: '$columnId = ? AND $columnIsDeleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return LocationRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<LocationRecord?> getLocationLogByClientTempId(
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
      return LocationRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<LocationRecord?> getLocationLogByServerId(
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
      return LocationRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<List<LocationRecord>> getLocationLogsForDate(
    DateTime date, {
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    final dateString = date.toIso8601String().substring(0, 10);
    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where: 'date($columnTimestamp) = ? AND $columnIsDeleted = 0',
      whereArgs: [dateString],
      orderBy: '$columnTimestamp DESC',
    );
    return maps.map((map) => LocationRecord.fromMap(map)).toList();
  }

  Future<List<LocationRecord>> getLocationsByDateRange(
    DateTime start,
    DateTime end, {
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where:
          '$columnTimestamp >= ? AND $columnTimestamp <= ? AND $columnIsDeleted = 0',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: '$columnTimestamp DESC',
    );
    return maps.map((map) => LocationRecord.fromMap(map)).toList();
  }

  Future<List<LocationRecord>> getUnsyncedLocationLogs({
    DateTime? lastSyncTimestamp,
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    // Get records that are created or updated, and not deleted
    String whereClause =
        '($columnSyncStatus = ? OR $columnSyncStatus = ?) AND $columnIsDeleted = 0';
    List<dynamic> whereArgs = [
      SyncStatus.created.name,
      SyncStatus.updated.name,
    ];

    if (lastSyncTimestamp != null) {
      whereClause += ' AND $columnUpdatedAt > ?';
      whereArgs.add(lastSyncTimestamp.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return maps.map((map) => LocationRecord.fromMap(map)).toList();
  }

  Future<List<LocationRecord>> getDeletedAndUnsyncedLocationLogs({
    DateTime? lastSyncTimestamp,
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    // Get records that are marked as deleted but not yet synced as deleted
    String whereClause = '$columnIsDeleted = 1 AND ($columnSyncStatus = ?)';

    List<dynamic> whereArgs = [SyncStatus.deleted.name];

    if (lastSyncTimestamp != null) {
      // If we only want to sync deletions that happened after the last sync
      whereClause += ' AND $columnUpdatedAt > ?';
      whereArgs.add(lastSyncTimestamp.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return maps.map((map) => LocationRecord.fromMap(map)).toList();
  }

  Future<void> markLocationLogsAsSynced(
    List<String> clientTempIds,
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    if (clientTempIds.isEmpty) {
      return;
    }

    final batch = dbExecutor.batch();
    final syncTimeStr = syncTimestamp.toIso8601String();

    for (String clientTempId in clientTempIds) {
      final updateData = <String, dynamic>{
        columnSyncStatus: SyncStatus.synced.name,
        columnLastSynced: syncTimeStr,
      };
      if (serverIds != null && serverIds.containsKey(clientTempId)) {
        updateData[columnServerId] = serverIds[clientTempId];
      }
      batch.update(
        tableName,
        updateData,
        where: '$columnClientTempId = ?',
        whereArgs: [clientTempId],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> applyLocationLogSyncChanges(
    List<LocationRecord> serverItems, {
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    final batch = dbExecutor.batch();

    for (final serverItem in serverItems) {
      LocationRecord? localItem;
      if (serverItem.serverId != null) {
        localItem = await getLocationLogByServerId(
          serverItem.serverId!,
          txn: txn,
        );
      }
      if (localItem == null && serverItem.clientTempId != null) {
        localItem = await getLocationLogByClientTempId(
          serverItem.clientTempId!,
          txn: txn,
        );
      }

      if (serverItem.isDeleted) {
        if (localItem != null && localItem.id != null) {
          // Soft delete if it exists locally and is not already deleted
          if (!localItem.isDeleted) {
            final deletedRecord = localItem.copyWith(
              isDeleted: true,
              syncStatus:
                  SyncStatus.synced, // Or a specific 'deleted_synced' status
              lastSynced: serverItem.lastSynced ?? DateTime.now(),
              updatedAt: serverItem.updatedAt ?? DateTime.now(),
            );
            batch.update(
              tableName,
              deletedRecord.toMap(),
              where: '$columnId = ?',
              whereArgs: [localItem.id],
            );
          } else if (localItem.isDeleted &&
              localItem.syncStatus != SyncStatus.synced) {
            // If already soft-deleted locally but not marked as synced, mark it now.
            final Map<String, dynamic> updateFields = {
              columnSyncStatus: SyncStatus.synced.name,
              columnLastSynced:
                  (serverItem.lastSynced ?? DateTime.now()).toIso8601String(),
            };
            batch.update(
              tableName,
              updateFields,
              where: '$columnId = ?',
              whereArgs: [localItem.id],
            );
          }
        }
        // If server item is deleted and not found locally, nothing to do.
      } else {
        // Upsert logic for non-deleted items
        final itemToSave = serverItem.copyWith(
          syncStatus: SyncStatus.synced,
          lastSynced: serverItem.lastSynced ?? DateTime.now(),
          // Ensure clientTempId is preserved if serverItem has it and localItem (if any) doesn't,
          // or if inserting anew and serverItem provides it.
          clientTempId: localItem?.clientTempId ?? serverItem.clientTempId,
          id: localItem?.id, // Use existing local ID if found
        );

        if (localItem != null && localItem.id != null) {
          // Update existing
          // Only update if server data is newer (e.g., based on serverItem.updatedAt)
          // For simplicity, we'll assume server data is authoritative here.
          batch.update(
            tableName,
            itemToSave.toMap(),
            where: '$columnId = ?',
            whereArgs: [localItem.id],
          );
        } else {
          // Insert new
          final newId =
              itemToSave.id ??
              'local_loc_${DateTime.now().millisecondsSinceEpoch}_${itemToSave.hashCode}';
          final recordToInsert = itemToSave.copyWith(
            id: newId,
            // if clientTempId is null on serverItem, generate one if it's a truly new record.
            // However, for applyChanges, serverItem should ideally have a clientTempId if it originated from a client.
            // If serverId is present, clientTempId might be less critical for matching.
            clientTempId:
                itemToSave.clientTempId ??
                (itemToSave.serverId == null
                    ? 'client_loc_sync_${DateTime.now().millisecondsSinceEpoch}_${itemToSave.hashCode}'
                    : null),
          );
          batch.insert(
            tableName,
            recordToInsert.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveLocationLog(
    LocationRecord record, {
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    LocationRecord? existingRecord;

    if (record.id != null) {
      existingRecord = await getLocationLogById(record.id!, txn: txn);
    }
    if (existingRecord == null && record.clientTempId != null) {
      existingRecord = await getLocationLogByClientTempId(
        record.clientTempId!,
        txn: txn,
      );
    }
    if (existingRecord == null && record.serverId != null) {
      existingRecord = await getLocationLogByServerId(
        record.serverId!,
        txn: txn,
      );
    }

    if (existingRecord != null) {
      final updatedLog = record.copyWith(
        id: existingRecord.id,
        serverId: existingRecord.serverId ?? record.serverId,
        clientTempId: existingRecord.clientTempId ?? record.clientTempId,
        syncStatus:
            (existingRecord.syncStatus == SyncStatus.synced &&
                    record.isDeleted == existingRecord.isDeleted)
                ? SyncStatus.updated
                : (record.isDeleted ? SyncStatus.deleted : SyncStatus.updated),
        updatedAt: DateTime.now(),
        // Preserve creation timestamp if not provided in 'record' -> Corrected: record.timestamp is not nullable
        timestamp: record.timestamp,
        // Preserve userId if not provided in 'record' -> Corrected: record.userId is not nullable
        userId: record.userId,
        latitude:
            record
                .latitude, // Ensure all fields are passed through or preserved
        longitude: record.longitude,
        lastSynced: record.lastSynced, // Pass through or it might be lost
        isDeleted: record.isDeleted, // Pass through
      );
      await dbExecutor.update(
        tableName,
        updatedLog.toMap(),
        where: '$columnId = ?',
        whereArgs: [existingRecord.id],
      );
    } else {
      // Insert new record
      final newLog = record.copyWith(
        clientTempId:
            record.clientTempId ??
            'client_loc_${DateTime.now().millisecondsSinceEpoch}_${record.hashCode}',
        id:
            record.id ??
            'local_loc_${DateTime.now().millisecondsSinceEpoch}_${record.hashCode}',
        syncStatus: record.isDeleted ? SyncStatus.deleted : SyncStatus.created,
        updatedAt: DateTime.now(),
      );
      await dbExecutor.insert(
        tableName,
        newLog.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> clearAllData({Transaction? txn}) async {
    final dbExecutor = txn ?? db;
    await dbExecutor.delete(tableName);
  }

  Future<void> hardDeleteLocationLog(String id, {Transaction? txn}) async {
    final dbExecutor = txn ?? db;
    await dbExecutor.delete(tableName, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<bool> hasUnsyncedLocationChanges({
    DateTime? lastSyncTimestamp,
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    String whereClause =
        '($columnSyncStatus = ? OR $columnSyncStatus = ? OR $columnSyncStatus = ?)';

    List<dynamic> whereArgs = [
      SyncStatus.created.name,
      SyncStatus.updated.name,
      SyncStatus.deleted.name,
    ];

    if (lastSyncTimestamp != null) {
      whereClause += ' AND $columnUpdatedAt > ?';
      whereArgs.add(lastSyncTimestamp.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<List<LocationRecord>> getLocationsForUserAndDate(
    String userId,
    DateTime date, {
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    final dateString = date.toIso8601String().substring(0, 10);
    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where:
          '$columnUserId = ? AND date($columnTimestamp) = ? AND $columnIsDeleted = 0',
      whereArgs: [userId, dateString],
      orderBy: '$columnTimestamp DESC',
    );
    return maps.map((map) => LocationRecord.fromMap(map)).toList();
  }

  Future<List<LocationRecord>> getAllLocationLogsForUser(
    String userId, {
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where: '$columnUserId = ? AND $columnIsDeleted = 0',
      whereArgs: [userId],
      orderBy: '$columnTimestamp DESC',
    );
    return maps.map((map) => LocationRecord.fromMap(map)).toList();
  }

  Future<List<LocationRecord>> getLocationLogsForUserInRange(
    String userId,
    DateTime startDate,
    DateTime endDate, {
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    final List<Map<String, dynamic>> maps = await dbExecutor.query(
      tableName,
      where:
          '$columnUserId = ? AND $columnTimestamp >= ? AND $columnTimestamp <= ? AND $columnIsDeleted = 0',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: '$columnTimestamp DESC',
    );
    return maps.map((map) => LocationRecord.fromMap(map)).toList();
  }

  Future<void> deleteLocationLogsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate, {
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    // Soft delete: update isDeleted and syncStatus
    final locationsToMark = await getLocationLogsForUserInRange(
      userId,
      startDate,
      endDate,
      txn: txn,
    );
    if (locationsToMark.isEmpty) return;

    final batch = dbExecutor.batch();
    final now = DateTime.now();
    final nowStr = now.toIso8601String();

    for (final loc in locationsToMark) {
      if (loc.id != null) {
        batch.update(
          tableName,
          {
            columnIsDeleted: 1,
            columnSyncStatus: SyncStatus.deleted.name,
            columnUpdatedAt: nowStr,
          },
          where: '$columnId = ?',
          whereArgs: [loc.id],
        );
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAllLocationLogsForUser(
    String userId, {
    Transaction? txn,
  }) async {
    final dbExecutor = txn ?? db;
    // Soft delete all for user
    final locationsToMark = await getAllLocationLogsForUser(userId, txn: txn);
    if (locationsToMark.isEmpty) return;

    final batch = dbExecutor.batch();
    final now = DateTime.now();
    final nowStr = now.toIso8601String();

    for (final loc in locationsToMark) {
      if (loc.id != null) {
        batch.update(
          tableName,
          {
            columnIsDeleted: 1,
            columnSyncStatus: SyncStatus.deleted.name,
            columnUpdatedAt: nowStr,
          },
          where: '$columnId = ?',
          whereArgs: [loc.id],
        );
      }
    }
    await batch.commit(noResult: true);
  }
}
