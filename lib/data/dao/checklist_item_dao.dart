import 'package:sqflite/sqflite.dart';
import 'package:recap_today/model/checklist_item_model.dart';
import 'package:recap_today/model/sync_status.dart';
import 'package:recap_today/data/database_helper.dart';
import 'package:uuid/uuid.dart'; // For generating clientGeneratedId if needed

class ChecklistItemDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String tableName =
      'checklist_items'; // Use DatabaseHelper.checklistItemTable

  // Helper to get DB instance, supporting transactions
  Future<DatabaseExecutor> _getDb(Transaction? txn) async {
    return txn ?? await _dbHelper.database;
  }

  Future<int> insert(ChecklistItem item, {Transaction? txn}) async {
    final db = await _getDb(txn);
    return await db.insert(
      tableName, // Use constant
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ChecklistItem?> getById(String id, {Transaction? txn}) async {
    // id is likely serverId or clientGeneratedId if not synced
    final db = await _getDb(txn);
    final maps = await db.query(
      tableName,
      where: 'id = ? OR clientGeneratedId = ?', // Check both possible ID fields
      whereArgs: [id, id],
    );
    if (maps.isNotEmpty) {
      return ChecklistItem.fromMap(maps.first);
    }
    return null;
  }

  Future<ChecklistItem?> getByClientGeneratedId(
    String clientGeneratedId, {
    Transaction? txn,
  }) async {
    final db = await _getDb(txn);
    final maps = await db.query(
      tableName,
      where: 'clientGeneratedId = ?',
      whereArgs: [clientGeneratedId],
    );
    if (maps.isNotEmpty) {
      return ChecklistItem.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ChecklistItem>> getAllByChecklistId(
    String checklistId, {
    Transaction? txn,
  }) async {
    final db = await _getDb(txn);
    final maps = await db.query(
      tableName,
      where: 'checklistId = ?',
      whereArgs: [checklistId],
      orderBy: 'createdAt ASC',
    );
    return maps.map((map) => ChecklistItem.fromMap(map)).toList();
  }

  Future<int> update(ChecklistItem item, {Transaction? txn}) async {
    final db = await _getDb(txn);
    return await db.update(
      tableName,
      item.toMap(),
      where:
          'clientGeneratedId = ?', // Prefer clientGeneratedId for updates before serverId is known
      whereArgs: [item.clientGeneratedId],
    );
  }

  Future<int> delete(String clientGeneratedId, {Transaction? txn}) async {
    // Changed to clientGeneratedId
    final db = await _getDb(txn);
    return await db.delete(
      tableName,
      where: 'clientGeneratedId = ?', // Use clientGeneratedId
      whereArgs: [clientGeneratedId],
    );
  }

  // New methods required by SqfliteDatabase
  Future<void> saveAllItems(
    List<ChecklistItem> items, {
    Transaction? txn,
  }) async {
    final db = await _getDb(txn);
    final batch = db.batch();
    for (final item in items) {
      // Ensure clientGeneratedId is present
      final Map<String, dynamic> itemMap = item.toMap();
      if (itemMap['clientGeneratedId'] == null) {
        throw ArgumentError(
          'clientGeneratedId cannot be null when saving ChecklistItem',
        );
      }
      batch.insert(
        tableName,
        itemMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<ChecklistItem>> getAllItems({Transaction? txn}) async {
    final db = await _getDb(txn);
    final maps = await db.query(tableName, orderBy: 'createdAt ASC');
    return maps.map((map) => ChecklistItem.fromMap(map)).toList();
  }

  Future<void> deleteAllItems({Transaction? txn}) async {
    final db = await _getDb(txn);
    await db.delete(tableName);
  }

  Future<void> importItems(
    List<Map<String, dynamic>> itemsData,
    DateTime syncTime, {
    Transaction? txn,
  }) async {
    final db = await _getDb(txn);
    final batch = db.batch();
    var uuid = Uuid();

    for (final itemMap in itemsData) {
      // Minimal validation and transformation
      final String serverId =
          itemMap['id'] ??
          itemMap['serverId'] ??
          uuid.v4(); // Ensure serverId exists
      String clientGeneratedId =
          itemMap['clientTempId'] ?? itemMap['clientGeneratedId'] ?? serverId;

      // Check if item with this serverId already exists
      final existingItemMaps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [serverId],
        limit: 1,
      );

      ChecklistItem itemToSave;
      if (existingItemMaps.isNotEmpty) {
        // Item exists, update it
        final existingItem = ChecklistItem.fromMap(existingItemMaps.first);
        itemToSave = ChecklistItem(
          id: serverId, // Server ID
          checklistId: itemMap['checklistId'] ?? existingItem.checklistId,
          content:
              itemMap['text'] ?? itemMap['content'] ?? existingItem.content,
          isCompleted: itemMap['isChecked'] ?? existingItem.isCompleted,
          clientGeneratedId:
              clientGeneratedId, // Use existing or new clientGeneratedId
          createdAt:
              itemMap['createdAt'] != null
                  ? DateTime.parse(itemMap['createdAt'])
                  : existingItem.createdAt,
          updatedAt: syncTime, // Server's sync time
          syncStatus: SyncStatus.synced,
        );
      } else {
        // Item does not exist, create new
        itemToSave = ChecklistItem(
          id: serverId, // Server ID
          checklistId:
              itemMap['checklistId'] ??
              'default_checklist_id', // Provide a default or handle error
          content: itemMap['text'] ?? itemMap['content'] ?? 'Imported Item',
          isCompleted: itemMap['isChecked'] ?? false,
          clientGeneratedId: clientGeneratedId,
          createdAt:
              itemMap['createdAt'] != null
                  ? DateTime.parse(itemMap['createdAt'])
                  : syncTime,
          updatedAt: syncTime,
          syncStatus: SyncStatus.synced,
        );
      }
      batch.insert(
        tableName,
        itemToSave.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // Updated sync-related methods
  Future<List<ChecklistItem>> getUnsyncedItems({
    DateTime? lastSyncTimestamp,
    Transaction? txn,
  }) async {
    final db = await _getDb(txn);
    // If lastSyncTimestamp is provided, filter by updatedAt > lastSyncTimestamp AND syncStatus != synced
    // For now, sticking to the simpler syncStatus check as per previous DAO logic
    final query =
        lastSyncTimestamp != null
            ? 'syncStatus != ? AND updatedAt > ?'
            : 'syncStatus != ?';
    final args =
        lastSyncTimestamp != null
            ? [SyncStatus.synced.name, lastSyncTimestamp.toIso8601String()]
            : [SyncStatus.synced.name];

    final maps = await db.query(tableName, where: query, whereArgs: args);
    return maps.map((map) => ChecklistItem.fromMap(map)).toList();
  }

  Future<void> markAsSynced(
    List<String> clientGeneratedIds, {
    DateTime? syncTimestamp,
    Map<String, String>? serverIds,
    Transaction? txn,
  }) async {
    final db = await _getDb(txn);
    final batch = db.batch();
    DateTime effectiveSyncTime = syncTimestamp ?? DateTime.now();

    for (String clientGeneratedId in clientGeneratedIds) {
      String? serverId = serverIds?[clientGeneratedId];

      final updateData = {
        'syncStatus': SyncStatus.synced.name,
        'updatedAt': effectiveSyncTime.toIso8601String(),
        if (serverId != null) 'id': serverId, // Update the main ID to serverId
      };

      batch.update(
        tableName,
        updateData,
        where: 'clientGeneratedId = ?',
        whereArgs: [clientGeneratedId],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> applySyncChanges(
    List<ChecklistItem> itemsToUpdate,
    List<String> serverDeletedIds, {
    Transaction? txn,
  }) async {
    final db = await _getDb(txn);
    final batch = db.batch();
    var uuid = Uuid();

    for (final itemData in itemsToUpdate) {
      // itemData is already a ChecklistItem from server
      // Server items should have their server ID in itemData.id
      // clientGeneratedId might be new or match an existing one if it was an update to a client item
      final Map<String, dynamic> itemMap = itemData.toMap();

      // Ensure clientGeneratedId exists, if not, use server ID or generate new for local tracking
      if (itemMap['clientGeneratedId'] == null) {
        itemMap['clientGeneratedId'] = itemData.id ?? uuid.v4();
      }
      // Ensure id (server id) is present
      if (itemMap['id'] == null && itemData.id != null) {
        itemMap['id'] = itemData.id;
      } else if (itemMap['id'] == null && itemData.id == null) {
        // This case should ideally not happen if itemsToUpdate are from server
        // but as a fallback, use clientGeneratedId as id if id is truly missing.
        itemMap['id'] = itemMap['clientGeneratedId'];
      }

      itemMap['syncStatus'] =
          SyncStatus.synced.name; // Items from server are considered synced
      itemMap['updatedAt'] =
          DateTime.now()
              .toIso8601String(); // Or use a server-provided timestamp

      batch.insert(
        tableName,
        itemMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (final serverIdToDelete in serverDeletedIds) {
      // These are server IDs
      batch.delete(
        tableName,
        where: 'id = ?', // Delete by server ID
        whereArgs: [serverIdToDelete],
      );
    }
    await batch.commit(noResult: true);
  }
}
