import 'package:sqflite/sqflite.dart';
import '../../model/checklist_item.dart';
import '../../model/sync_status.dart' as model_sync_status;

class ChecklistDao {
  final Database _db;
  static const String tableName =
      'checklistItems'; // Made tableName a static const

  ChecklistDao(this._db);

  static Future<void> createTable(
    Database db, {
    bool ifNotExists = false,
  }) async {
    final String createSql = '''
      CREATE TABLE ${ifNotExists ? 'IF NOT EXISTS ' : ''}$tableName (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        subtext TEXT,
        isChecked INTEGER NOT NULL DEFAULT 0,
        dueDate TEXT,
        completedDate TEXT,
        lastSynced INTEGER NOT NULL, -- Ensure this matches model (epoch milliseconds)
        serverId TEXT UNIQUE,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        clientTempId TEXT UNIQUE,
        syncStatus TEXT NOT NULL -- Stored as string name of the enum
      )
    ''';
    await db.execute(createSql);
  }

  static Future<void> upgradeTable(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Simplified upgrade logic: For complex migrations, consider a migration framework
    // This example just ensures all columns exist, it doesn't handle data type changes or complex alterations.
    final columns = {
      'id': 'TEXT PRIMARY KEY',
      'text': 'TEXT NOT NULL',
      'subtext': 'TEXT',
      'isChecked': 'INTEGER NOT NULL DEFAULT 0',
      'dueDate': 'TEXT',
      'completedDate': 'TEXT',
      'lastSynced': 'INTEGER NOT NULL',
      'serverId': 'TEXT UNIQUE',
      'isDeleted': 'INTEGER NOT NULL DEFAULT 0',
      'clientTempId': 'TEXT UNIQUE',
      'syncStatus': 'TEXT NOT NULL',
    };

    var tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
    List<String> existingColumns =
        tableInfo.map((row) => row['name'] as String).toList();

    for (var columnEntry in columns.entries) {
      if (!existingColumns.contains(columnEntry.key)) {
        // Avoid altering PRIMARY KEY or NOT NULL without DEFAULT in a simple ALTER TABLE ADD COLUMN
        // More complex changes might require creating a new table and copying data.
        if (!columnEntry.value.contains('PRIMARY KEY') &&
            !(columnEntry.value.contains('NOT NULL') &&
                !columnEntry.value.contains('DEFAULT'))) {
          try {
            await db.execute(
              'ALTER TABLE $tableName ADD COLUMN ${columnEntry.key} ${columnEntry.value}',
            );
            print('Added column ${columnEntry.key} to $tableName');
          } catch (e) {
            print(
              'Error adding column ${columnEntry.key} to $tableName: $e. Manual migration might be needed.',
            );
          }
        } else {
          print(
            'Skipping add of column ${columnEntry.key} due to PRIMARY KEY or NOT NULL constraint without DEFAULT. Manual migration might be needed.',
          );
        }
      }
    }
  }

  Future<int> insertChecklistItem(
    ChecklistItem item, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    return await dbClient.insert(
      tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChecklistItem>> getChecklistItems({Transaction? txn}) async {
    final dbClient = txn ?? _db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      tableName,
      where: 'isDeleted = 0', // Exclude soft-deleted items by default
      orderBy: 'dueDate IS NULL, dueDate ASC, id ASC',
    );
    return List.generate(maps.length, (i) {
      return ChecklistItem.fromMap(maps[i]);
    });
  }

  Future<ChecklistItem?> getChecklistItemById(
    String id, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      tableName,
      where: 'id = ? AND isDeleted = 0',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ChecklistItem.fromMap(maps.first);
    }
    return null;
  }

  Future<ChecklistItem?> getChecklistItemByServerId(
    String serverId, {
    Transaction? txn,
  }) async {
    if (serverId.isEmpty) return null;
    final dbClient = txn ?? _db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      tableName,
      where: 'serverId = ? AND isDeleted = 0',
      whereArgs: [serverId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ChecklistItem.fromMap(maps.first);
    }
    return null;
  }

  Future<ChecklistItem?> getChecklistItemByClientTempId(
    String clientTempId, {
    Transaction? txn,
  }) async {
    if (clientTempId.isEmpty) return null;
    final dbClient = txn ?? _db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      tableName,
      where: 'clientTempId = ? AND isDeleted = 0',
      whereArgs: [clientTempId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ChecklistItem.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateChecklistItem(
    ChecklistItem item, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    return await dbClient.update(
      tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteChecklistItem(String id, {Transaction? txn}) async {
    final dbClient = txn ?? _db;
    // Soft delete by default, actual deletion should be handled by a separate method or sync process
    return await dbClient.update(
      tableName,
      {
        'isDeleted': 1,
        'syncStatus': model_sync_status.SyncStatus.deleted.name,
        'lastSynced': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> hardDeleteChecklistItem(String id, {Transaction? txn}) async {
    final dbClient = txn ?? _db;
    return await dbClient.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertAllItems(
    List<ChecklistItem> items, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    Batch batch = dbClient.batch();
    for (var item in items) {
      batch.insert(
        tableName,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAllItems({Transaction? txn}) async {
    final dbClient = txn ?? _db;
    await dbClient.delete(tableName);
  }

  Future<bool> hasUnsyncedChanges({
    DateTime? lastSyncTimestamp,
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    String whereClause = 'syncStatus != ?';
    List<dynamic> whereArgs = [model_sync_status.SyncStatus.synced.name];

    // If lastSyncTimestamp is provided, we are interested in changes *since* that time.
    // A record is considered unsynced if its lastSynced (local update time) is after the server's last successful sync time for this client.
    if (lastSyncTimestamp != null) {
      whereClause += ' AND lastSynced > ?';
      whereArgs.add(lastSyncTimestamp.millisecondsSinceEpoch);
    }

    final count = Sqflite.firstIntValue(
      await dbClient.rawQuery(
        'SELECT COUNT(*) FROM $tableName WHERE $whereClause',
        whereArgs,
      ),
    );
    return (count ?? 0) > 0;
  }

  Future<List<ChecklistItem>> getUnsyncedChecklistItems({
    DateTime? lastSyncTimestamp,
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    // Get items that are not synced OR are marked as deleted but not yet synced as deleted.
    String whereClause = 'syncStatus != ?';
    List<dynamic> whereArgs = [model_sync_status.SyncStatus.synced.name];

    if (lastSyncTimestamp != null) {
      whereClause += ' AND lastSynced > ?';
      whereArgs.add(lastSyncTimestamp.millisecondsSinceEpoch);
    }

    final List<Map<String, dynamic>> maps = await dbClient.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return List.generate(maps.length, (i) {
      return ChecklistItem.fromMap(maps[i]);
    });
  }

  Future<void> markChecklistItemsAsSynced(
    List<String> clientTempIds,
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    if (clientTempIds.isEmpty) return;

    Batch batch = dbClient.batch();
    for (String clientTempId in clientTempIds) {
      String? serverId = serverIds?[clientTempId];
      Map<String, dynamic> updateValues = {
        'syncStatus': model_sync_status.SyncStatus.synced.name,
        'lastSynced': syncTimestamp.millisecondsSinceEpoch,
      };
      if (serverId != null && serverId.isNotEmpty) {
        updateValues['serverId'] = serverId;
      }
      batch.update(
        tableName,
        updateValues,
        where: 'clientTempId = ?',
        whereArgs: [clientTempId],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> applyChecklistItemSyncChanges(
    List<ChecklistItem> serverItems, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    Batch batch = dbClient.batch();

    for (var serverItem in serverItems) {
      ChecklistItem? localItem;
      if (serverItem.serverId != null && serverItem.serverId!.isNotEmpty) {
        localItem = await getChecklistItemByServerId(
          serverItem.serverId!,
          txn: txn,
        );
      }
      // If not found by serverId, try by clientTempId (e.g., item created locally and server is confirming)
      if (localItem == null &&
          serverItem.clientTempId != null &&
          serverItem.clientTempId!.isNotEmpty) {
        localItem = await getChecklistItemByClientTempId(
          serverItem.clientTempId!,
          txn: txn,
        );
      }

      final serverItemMap =
          serverItem
              .copyWith(syncStatus: model_sync_status.SyncStatus.synced)
              .toMap();

      if (localItem != null) {
        // Item exists locally
        if (serverItem.isDeleted) {
          // Server says delete
          batch.delete(tableName, where: 'id = ?', whereArgs: [localItem.id]);
        } else if (serverItem.lastSynced.isAfter(localItem.lastSynced)) {
          // Server item is newer, update local
          batch.update(
            tableName,
            serverItemMap,
            where: 'id = ?',
            whereArgs: [localItem.id],
            conflictAlgorithm:
                ConflictAlgorithm
                    .replace, // Ensure server data replaces local on conflict
          );
        }
      } else if (!serverItem.isDeleted) {
        // Item does not exist locally and is not deleted on server, insert it
        batch.insert(
          tableName,
          serverItemMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    await batch.commit(noResult: true);
  }
}
