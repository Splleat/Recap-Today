import 'dart:async';
import 'package:recap_today/model/photo_model.dart';
import 'package:recap_today/model/sync_status.dart';
import 'package:sqflite/sqflite.dart';

class PhotoDao {
  final Database _db; // Add this
  static const String tableName = 'photos';
  static const String columnId = 'id';
  static const String columnClientTempId = 'client_temp_id';
  static const String columnDiaryId = 'diary_id';
  static const String columnPath = 'path';
  static const String columnCaption = 'caption';
  static const String columnServerId = 'server_id';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnLastSynced = 'last_synced';
  static const String columnIsDeleted = 'is_deleted';
  static const String columnSyncStatus = 'sync_status';

  // Database getter - REMOVE or MODIFY if _db is directly used
  // Future<Database> get database async {
  //   return await DatabaseHelper.instance.database;
  // }

  // Constructor to accept Database instance
  PhotoDao(this._db); // Add this

  Future<void> createTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnClientTempId TEXT UNIQUE,
        $columnDiaryId INTEGER NOT NULL,
        $columnPath TEXT NOT NULL,
        $columnCaption TEXT,
        $columnServerId TEXT UNIQUE,
        $columnCreatedAt INTEGER NOT NULL,
        $columnUpdatedAt INTEGER NOT NULL,
        $columnLastSynced INTEGER,
        $columnIsDeleted INTEGER NOT NULL DEFAULT 0,
        $columnSyncStatus TEXT NOT NULL DEFAULT '${SyncStatus.created.name}',
        FOREIGN KEY ($columnDiaryId) REFERENCES diary(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> upgradeTable(
    DatabaseExecutor db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Example: Assuming version 2 adds new columns
      await db.execute('ALTER TABLE $tableName ADD COLUMN $columnCaption TEXT');
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnClientTempId TEXT UNIQUE',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnServerId TEXT UNIQUE',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnCreatedAt INTEGER',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnUpdatedAt INTEGER',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnLastSynced INTEGER',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnIsDeleted INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnSyncStatus TEXT NOT NULL DEFAULT \'${SyncStatus.created.name}\'',
      );
      // Set default createdAt and updatedAt for existing rows if necessary
      await db.rawUpdate(
        'UPDATE $tableName SET $columnCreatedAt = ?, $columnUpdatedAt = ? WHERE $columnCreatedAt IS NULL',
        [
          DateTime.now().millisecondsSinceEpoch,
          DateTime.now().millisecondsSinceEpoch,
        ],
      );
    }
    // Add more migration steps as needed for future versions
  }

  Future<Photo?> insertPhoto(Photo photo, {Transaction? txn}) async {
    final db = txn ?? _db; // Modify this
    final photoMap =
        photo
            .copyWith(
              createdAt: photo.createdAt, // Use provided or set to now
              updatedAt: photo.updatedAt, // Use provided or set to now
              syncStatus:
                  photo.serverId != null &&
                          photo.syncStatus == SyncStatus.synced
                      ? SyncStatus.synced
                      : SyncStatus.created,
            )
            .toMap();

    photoMap.remove('id'); // ID is autoincremented

    final id = await db.insert(
      tableName,
      photoMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id > 0 ? photo.copyWith(id: id) : null;
  }

  Future<Photo?> getPhotoById(int id, {Transaction? txn}) async {
    final db = txn ?? _db; // Modify this
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnId = ? AND $columnIsDeleted = 0',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Photo.fromMap(maps.first);
    }
    return null;
  }

  Future<Photo?> getPhotoByServerId(String serverId, {Transaction? txn}) async {
    final db = txn ?? _db; // Modify this
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnServerId = ?',
      whereArgs: [serverId],
    );
    if (maps.isNotEmpty) {
      return Photo.fromMap(maps.first);
    }
    return null;
  }

  Future<Photo?> getPhotoByClientTempId(
    String clientTempId, {
    Transaction? txn,
  }) async {
    final db = txn ?? _db; // Modify this
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnClientTempId = ?',
      whereArgs: [clientTempId],
    );
    if (maps.isNotEmpty) {
      return Photo.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Photo>> getPhotosForDiary(int diaryId, {Transaction? txn}) async {
    final db = txn ?? _db; // Modify this
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: '$columnDiaryId = ? AND $columnIsDeleted = 0',
      whereArgs: [diaryId],
      orderBy: '$columnCreatedAt ASC',
    );
    return maps.map((map) => Photo.fromMap(map)).toList();
  }

  Future<List<Photo>> getAllPhotos({
    bool includeDeleted = false,
    Transaction? txn,
  }) async {
    final db = txn ?? _db; // Modify this
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: includeDeleted ? null : '$columnIsDeleted = 0',
      orderBy: '$columnCreatedAt DESC',
    );
    return maps.map((map) => Photo.fromMap(map)).toList();
  }

  Future<int> updatePhoto(Photo photo, {Transaction? txn}) async {
    final db = txn ?? _db; // Modify this
    final now = DateTime.now();
    Photo photoToUpdate = photo.copyWith(updatedAt: now);

    // Only change syncStatus to updated if it was previously synced.
    // If it was created or already updated/deleted, its status should persist or be handled by specific operations.
    if (photo.syncStatus == SyncStatus.synced) {
      photoToUpdate = photoToUpdate.copyWith(syncStatus: SyncStatus.updated);
    }
    // No change to syncStatus if it's created, updated, or deleted already.
    // If it's created and gets a serverId, it means it's being synced,
    // so updatePhotoMetadataAfterSync or applyPhotoSyncChanges will set it to synced.

    return await db.update(
      tableName,
      photoToUpdate.toMap(),
      where: '$columnId = ?',
      whereArgs: [photo.id],
    );
  }

  Future<int> deletePhoto(
    int id, {
    bool hardDelete = false,
    Transaction? txn,
  }) async {
    final db = txn ?? _db; // Modify this
    if (hardDelete) {
      return await db.delete(
        tableName,
        where: '$columnId = ?',
        whereArgs: [id],
      );
    } else {
      // Soft delete
      final now = DateTime.now();
      final values = {
        columnUpdatedAt: now.millisecondsSinceEpoch,
        columnIsDeleted: 1,
        columnSyncStatus: SyncStatus.deleted.name,
      };
      return await db.update(
        tableName,
        values,
        where: '$columnId = ?',
        whereArgs: [id],
      );
    }
  }

  Future<int> deletePhotosForDiary(
    int diaryId, {
    bool hardDelete = false,
    Transaction? txn,
  }) async {
    final db = txn ?? _db; // Modify this
    if (hardDelete) {
      return await db.delete(
        tableName,
        where: '$columnDiaryId = ?',
        whereArgs: [diaryId],
      );
    } else {
      // Soft delete
      final now = DateTime.now();
      final values = {
        columnUpdatedAt: now.millisecondsSinceEpoch,
        columnIsDeleted: 1,
        columnSyncStatus: SyncStatus.deleted.name,
      };
      return await db.update(
        tableName,
        values,
        where: '$columnDiaryId = ? AND $columnIsDeleted = 0',
        whereArgs: [diaryId],
      );
    }
  }

  Future<List<Photo>> getUnsyncedPhotos({
    DateTime? lastSyncTimestamp,
    Transaction? txn,
  }) async {
    final db = txn ?? _db;
    // For now, ignoring lastSyncTimestamp and fetching all non-synced items.
    // A more complex implementation might use lastSyncTimestamp to also fetch items that are
    // SyncStatus.synced but have localPhoto.updatedAt > lastSyncTimestamp.
    String whereClause = '$columnSyncStatus != ?';
    List<dynamic> whereArgs = [SyncStatus.synced.name];

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return maps.map((map) => Photo.fromMap(map)).toList();
  }

  Future<void> applyPhotoSyncChanges(
    List<Photo> serverPhotos, {
    Transaction? txn,
  }) async {
    // final dbExecutor = txn ?? _db; // Modify this - Removed as unused
    // Use a transaction if not already provided to ensure atomicity for this complex operation
    if (txn == null) {
      // Ensure we have a Database instance to call transaction on
      return _db.transaction((txn) async {
        // Modify this
        await _applyPhotoSyncChangesInternal(serverPhotos, txn);
      });
    } else {
      // Already in a transaction, proceed directly
      return _applyPhotoSyncChangesInternal(serverPhotos, txn);
    }
  }

  Future<void> _applyPhotoSyncChangesInternal(
    List<Photo> serverPhotos,
    Transaction txn,
  ) async {
    final batch = txn.batch();

    for (final serverPhoto in serverPhotos) {
      // serverPhoto.diaryId is assumed to be the local diaryId,
      // resolved by the caller (e.g., SyncService) before calling this method.

      Photo? localPhoto;
      if (serverPhoto.serverId != null) {
        final List<Map<String, dynamic>> maps = await txn.query(
          tableName,
          where: '$columnServerId = ?',
          whereArgs: [serverPhoto.serverId!],
        );
        if (maps.isNotEmpty) localPhoto = Photo.fromMap(maps.first);
      }
      if (localPhoto == null && serverPhoto.clientTempId != null) {
        final List<Map<String, dynamic>> maps = await txn.query(
          tableName,
          where: '$columnClientTempId = ?',
          whereArgs: [serverPhoto.clientTempId!],
        );
        if (maps.isNotEmpty) localPhoto = Photo.fromMap(maps.first);
      }

      if (localPhoto != null) {
        if (serverPhoto.isDeleted) {
          // If server says delete, and we have it, delete it locally.
          batch.delete(
            tableName,
            where: '$columnId = ?',
            whereArgs: [localPhoto.id],
          );
        } else {
          // Server photo exists and is not deleted, local photo exists. Update local.
          // Use serverPhoto\\'s fields, ensure syncStatus is synced.
          final updatedLocalPhotoMap =
              serverPhoto
                  .copyWith(
                    id: localPhoto.id, // Keep local ID
                    diaryId:
                        serverPhoto
                            .diaryId, // Assume serverPhoto.diaryId is the correct local diaryId.
                    syncStatus: SyncStatus.synced,
                    lastSynced:
                        serverPhoto
                            .updatedAt, // Use server\\'s updatedAt as lastSynced
                  )
                  .toMap();
          batch.update(
            tableName,
            updatedLocalPhotoMap,
            where: '$columnId = ?',
            whereArgs: [localPhoto.id],
          );
        }
      } else if (!serverPhoto.isDeleted) {
        // Server photo exists, not deleted, but no local match. Insert new.
        // serverPhoto.diaryId must be the correct local diaryId.
        final newPhotoMap =
            serverPhoto
                .copyWith(
                  syncStatus: SyncStatus.synced,
                  lastSynced: serverPhoto.updatedAt,
                )
                .toMap();
        newPhotoMap.remove('id'); // Let DB assign new local ID
        batch.insert(tableName, newPhotoMap);
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> markPhotosAsSynced(
    List<String> clientTempIds,
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
    Transaction? txn,
  }) async {
    final db = txn ?? _db;
    final batch = db.batch();
    final syncTimeMillis = syncTimestamp.millisecondsSinceEpoch;

    for (final clientTempId in clientTempIds) {
      final String? serverId = serverIds?[clientTempId];
      final Map<String, dynamic> updateValues = {
        columnSyncStatus: SyncStatus.synced.name,
        columnLastSynced: syncTimeMillis,
        columnUpdatedAt: syncTimeMillis,
      };
      if (serverId != null) {
        updateValues[columnServerId] = serverId;
      }
      batch.update(
        tableName,
        updateValues,
        where: '$columnClientTempId = ?',
        whereArgs: [clientTempId],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<bool> hasUnsyncedPhotoChanges({
    DateTime? lastSyncTimestamp,
    Transaction? txn,
  }) async {
    final db = txn ?? _db;

    var count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $tableName WHERE $columnSyncStatus != ? AND $columnIsDeleted = 0',
        [SyncStatus.synced.name],
      ),
    );
    if (count != null && count > 0) {
      return true;
    }

    if (lastSyncTimestamp != null) {
      count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM $tableName WHERE $columnSyncStatus = ? AND $columnUpdatedAt > ? AND $columnIsDeleted = 0',
          [SyncStatus.synced.name, lastSyncTimestamp.millisecondsSinceEpoch],
        ),
      );
      if (count != null && count > 0) {
        return true;
      }
    }
    return false;
  }

  Future<void> importPhotos(
    List<Map<String, dynamic>> photosData,
    DateTime syncTime, {
    Transaction? txn,
  }) async {
    final db = txn ?? _db;
    final batch = db.batch();
    // final syncTimeMillis = syncTime.millisecondsSinceEpoch; // Unused

    for (var photoMap in photosData) {
      Photo photo = Photo.fromMap(photoMap);
      photo = photo.copyWith(
        lastSynced: syncTime,
        syncStatus: SyncStatus.synced, // Imported items are considered synced
        updatedAt:
            photoMap['updated_at'] != null
                ? DateTime.fromMillisecondsSinceEpoch(photoMap['updated_at'])
                : syncTime,
        createdAt:
            photoMap['created_at'] != null
                ? DateTime.fromMillisecondsSinceEpoch(photoMap['created_at'])
                : syncTime,
      );

      Map<String, dynamic> mapToInsert = photo.toMap();
      mapToInsert.remove('id'); // Allow auto-increment for local ID

      // Check if diaryId exists, otherwise this will fail due to foreign key constraint
      // This check should ideally be more robust or handled by the caller (SyncService)
      // For now, we assume diaryId in photosData is valid.

      if (photo.serverId != null) {
        // Try to find by serverId to update if it exists
        final List<Map<String, dynamic>> existing = await db.query(
          tableName,
          where: '$columnServerId = ?',
          whereArgs: [photo.serverId!],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          mapToInsert[columnId] =
              existing.first[columnId]; // Get local id to update
          batch.update(
            tableName,
            mapToInsert,
            where: '$columnId = ?',
            whereArgs: [mapToInsert[columnId]],
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          batch.insert(
            tableName,
            mapToInsert,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } else if (photo.clientTempId != null) {
        // Try to find by clientTempId if serverId is not present (e.g. new item from another client before first sync)
        final List<Map<String, dynamic>> existing = await db.query(
          tableName,
          where: '$columnClientTempId = ?',
          whereArgs: [photo.clientTempId!],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          mapToInsert[columnId] = existing.first[columnId];
          batch.update(
            tableName,
            mapToInsert,
            where: '$columnId = ?',
            whereArgs: [mapToInsert[columnId]],
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          batch.insert(
            tableName,
            mapToInsert,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      } else {
        // No serverId or clientTempId, just insert - this case should be rare for synced data
        batch.insert(
          tableName,
          mapToInsert,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    await batch.commit(noResult: true);
  }
} // End of PhotoDao class
