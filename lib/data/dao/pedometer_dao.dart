import 'package:recap_today/model/pedometer_data.dart';
import 'package:recap_today/model/sync_status.dart';
import 'package:sqflite/sqflite.dart';

class PedometerDao {
  final Database _db;
  static const String tableName = 'pedometer';

  PedometerDao(this._db);

  Future<void> initTable(Transaction txn) async {
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientTempId TEXT UNIQUE NOT NULL,
        serverId TEXT UNIQUE,
        date TEXT NOT NULL,
        steps INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        syncStatus TEXT NOT NULL,
        lastSynced TEXT
      )
    ''');
    // Add indexes for frequently queried columns
    await txn.execute(
      'CREATE INDEX IF NOT EXISTS idx_pedometer_date ON $tableName (date);',
    );
    await txn.execute(
      'CREATE INDEX IF NOT EXISTS idx_pedometer_client_temp_id ON $tableName (clientTempId);',
    );
    await txn.execute(
      'CREATE INDEX IF NOT EXISTS idx_pedometer_server_id ON $tableName (serverId);',
    );
    await txn.execute(
      'CREATE INDEX IF NOT EXISTS idx_pedometer_sync_status ON $tableName (syncStatus);',
    );
  }

  Future<int> insertPedometerData(
    PedometerData data, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    return await dbClient.insert(
      tableName,
      data
          .copyWith(syncStatus: SyncStatus.created, updatedAt: DateTime.now())
          .toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PedometerData?> getPedometerDataByDate(
    DateTime date, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      tableName,
      where: 'date = ?',
      // Ensure only the date part is used for comparison, without time component.
      whereArgs: [date.toIso8601String().substring(0, 10)],
    );
    if (maps.isNotEmpty) {
      return PedometerData.fromMap(maps.first);
    }
    return null;
  }

  Future<List<PedometerData>> getPedometerDataForDateRange(
    DateTime startDate,
    DateTime endDate, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      tableName,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String().substring(0, 10),
        endDate.toIso8601String().substring(0, 10),
      ],
      orderBy: 'date DESC',
    );
    return maps.map((map) => PedometerData.fromMap(map)).toList();
  }

  Future<int> updatePedometerData(
    PedometerData data, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    SyncStatus newSyncStatus = data.syncStatus;
    // If the item was synced, and is now being changed locally, mark as updated.
    // If it was already in a non-synced state (created, updated, deleted), keep that state.
    if (data.syncStatus == SyncStatus.synced) {
      newSyncStatus = SyncStatus.updated;
    }
    return await dbClient.update(
      tableName,
      data
          .copyWith(syncStatus: newSyncStatus, updatedAt: DateTime.now())
          .toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  Future<int> deletePedometerData(int id, {Transaction? txn}) async {
    // This is a hard delete. For sync, a soft delete (marking as deleted) is preferred.
    // This method should ideally be removed or changed to softDelete if hard deletes are only post-sync confirmation.
    final dbClient = txn ?? _db;
    // To implement soft delete here, you would first fetch the item to get its clientTempId,
    // then call softDeletePedometerData(clientTempId, txn: txn).
    // For now, keeping it as a hard delete as per original structure, but flagging for review.
    return await dbClient.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Methods for synchronization
  Future<PedometerData?> getPedometerDataByClientTempId(
    String clientTempId, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      tableName,
      where: 'clientTempId = ?',
      whereArgs: [clientTempId],
    );
    if (maps.isNotEmpty) {
      return PedometerData.fromMap(maps.first);
    }
    return null;
  }

  Future<PedometerData?> getPedometerDataByServerId(
    String serverId, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      tableName,
      where: 'serverId = ?',
      whereArgs: [serverId],
    );
    if (maps.isNotEmpty) {
      return PedometerData.fromMap(maps.first);
    }
    return null;
  }

  Future<List<PedometerData>> getUnsyncedPedometerData({
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      tableName,
      where:
          'syncStatus != ? AND syncStatus != ?', // Exclude synced and deleted (if soft deleted items are not meant to be re-uploaded without specific logic)
      whereArgs: [SyncStatus.synced.name, SyncStatus.deleted.name],
      orderBy: 'updatedAt ASC', // Process older changes first
    );
    return maps.map((map) => PedometerData.fromMap(map)).toList();
  }

  Future<void> markPedometerDataAsSynced(
    List<Map<String, String>> clientServerIdMap,
    DateTime lastSynced, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    final batch = dbClient.batch();

    for (var idPair in clientServerIdMap) {
      String clientTempId = idPair['clientTempId']!;
      String serverId = idPair['serverId']!;
      batch.update(
        tableName,
        {
          'syncStatus': SyncStatus.synced.name,
          'serverId': serverId,
          'lastSynced': lastSynced.toIso8601String(),
          'updatedAt':
              DateTime.now()
                  .toIso8601String(), // Record when this local record was marked synced
        },
        where: 'clientTempId = ?',
        whereArgs: [clientTempId],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> applyPedometerDataSyncChanges(
    List<PedometerData> serverDataList, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    final batch = dbClient.batch();
    final DateTime syncTime = DateTime.now();

    for (var serverData in serverDataList) {
      PedometerData? localData;
      if (serverData.serverId != null && serverData.serverId!.isNotEmpty) {
        localData = await getPedometerDataByServerId(
          serverData.serverId!,
          txn: txn,
        );
      }
      // If not found by serverId, try by clientTempId (e.g., server is confirming a client-initiated creation)
      localData ??= await getPedometerDataByClientTempId(
        serverData.clientTempId,
        txn: txn,
      );

      if (localData != null) {
        // Entry exists
        if (serverData.syncStatus == SyncStatus.deleted) {
          // Server indicates this item should be deleted
          batch.delete(tableName, where: 'id = ?', whereArgs: [localData.id]);
        } else if (serverData.updatedAt.isAfter(localData.updatedAt) ||
            localData.syncStatus != SyncStatus.synced) {
          // Update if server data is newer, or if local data was pending sync and server confirms/overwrites
          batch.update(
            tableName,
            serverData
                .copyWith(
                  id: localData.id,
                  syncStatus: SyncStatus.synced,
                  lastSynced: syncTime,
                )
                .toMap(),
            where: 'id = ?',
            whereArgs: [localData.id],
          );
        }
      } else if (serverData.syncStatus != SyncStatus.deleted) {
        // Entry does not exist locally, and server version is not a delete instruction, so insert.
        batch.insert(
          tableName,
          serverData
              .copyWith(syncStatus: SyncStatus.synced, lastSynced: syncTime)
              .toMap(),
          conflictAlgorithm:
              ConflictAlgorithm
                  .replace, // Or .ignore if server might send redundant creations
        );
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> updatePedometerServerIdAndMarkSynced(
    String clientTempId,
    String serverId,
    DateTime syncTimestamp, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    await dbClient.update(
      tableName,
      {
        'serverId': serverId,
        'syncStatus': SyncStatus.synced.name,
        'lastSynced': syncTimestamp.toIso8601String(),
        'updatedAt':
            DateTime.now()
                .toIso8601String(), // record the update time of this action
      },
      where: 'clientTempId = ?',
      whereArgs: [clientTempId],
    );
  }

  // Soft delete: mark as deleted for sync
  Future<int> softDeletePedometerDataByClientTempId(
    String clientTempId, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    // Check if item exists and is not already marked deleted to avoid unnecessary updates
    final existing = await getPedometerDataByClientTempId(
      clientTempId,
      txn: txn,
    );
    if (existing != null && existing.syncStatus != SyncStatus.deleted) {
      return await dbClient.update(
        tableName,
        {
          'syncStatus': SyncStatus.deleted.name,
          'updatedAt': DateTime.now().toIso8601String(),
          'serverId':
              existing
                  .serverId, // Ensure serverId is preserved for the delete sync action
        },
        where: 'clientTempId = ?',
        whereArgs: [clientTempId],
      );
    }
    return 0; // No update was performed
  }

  // Hard delete: remove from local DB, usually after server confirms deletion
  Future<int> hardDeletePedometerDataByClientTempId(
    String clientTempId, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    return await dbClient.delete(
      tableName,
      where: 'clientTempId = ?',
      whereArgs: [clientTempId],
    );
  }

  Future<int> hardDeletePedometerDataByServerId(
    String serverId, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    return await dbClient.delete(
      tableName,
      where: 'serverId = ?',
      whereArgs: [serverId],
    );
  }

  Future<void> clearAllPedometerData({Transaction? txn}) async {
    final dbClient = txn ?? _db;
    await dbClient.delete(tableName);
  }
}
