import 'package:sqflite/sqflite.dart';
import 'package:recap_today/model/diary_model.dart';
import 'package:recap_today/model/photo_model.dart';
import 'package:recap_today/model/sync_status.dart';
import 'package:recap_today/data/dao/photo_dao.dart';

class DiaryDao {
  static const String tableDiaries = 'diaries';
  static const String columnSyncStatus =
      'syncStatus'; // Added column name for syncStatus
  static const String columnServerId =
      'serverId'; // Added column name for serverId
  static const String columnClientTempId =
      'clientTempId'; // Added column name for clientTempId
  static const String columnLastSynced =
      'lastSynced'; // Added column name for lastSynced
  static const String columnIsDeleted =
      'isDeleted'; // Added column name for isDeleted

  final Database db;
  final PhotoDao photoDao;

  DiaryDao(this.db) : photoDao = PhotoDao(db);

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableDiaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        content TEXT,
        $columnClientTempId TEXT UNIQUE, 
        $columnServerId TEXT UNIQUE, 
        $columnLastSynced INTEGER,
        $columnIsDeleted INTEGER NOT NULL DEFAULT 0,
        $columnSyncStatus TEXT 
      )
    ''');
  }

  static Future<void> upgradeTable(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 18) {
      // Assuming 18 is the new version for this change
      await _addColumnIfNotExists(db, tableDiaries, columnSyncStatus, 'TEXT');
    }
    if (oldVersion < 17) {
      await _addColumnIfNotExists(
        db,
        tableDiaries,
        'clientTempId',
        'TEXT UNIQUE',
      );
    }
    if (oldVersion < 16) {
      await _addColumnIfNotExists(
        db,
        tableDiaries,
        columnServerId,
        'TEXT UNIQUE',
      );
      await _addColumnIfNotExists(
        db,
        tableDiaries,
        columnLastSynced,
        'INTEGER', // Removed NOT NULL DEFAULT 0, as it's now nullable
      );
      await _addColumnIfNotExists(
        db,
        tableDiaries,
        columnIsDeleted,
        'INTEGER NOT NULL DEFAULT 0',
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

  Future<DiaryModel> saveDiary(DiaryModel diary) async {
    return await db.transaction((txn) async {
      Map<String, dynamic> diaryMap = diary.toMapWithoutPhotos();
      // Ensure clientTempId is set if it's a new diary and clientTempId is provided
      if (diary.id == null && diary.clientTempId != null) {
        diaryMap[columnClientTempId] = diary.clientTempId;
      }

      // Determine sync status
      SyncStatus statusToSet;
      if (diary.isDeleted) {
        statusToSet = SyncStatus.deleted;
      } else if (diary.syncStatus == SyncStatus.synced &&
          diary.serverId != null) {
        // If it was synced and then modified locally (but not deleted)
        statusToSet = SyncStatus.updated;
      } else if (diary.serverId != null) {
        // If it has a serverId but status is not explicitly set to synced (e.g. during initial pull from server)
        // or if it's an update to an already synced item.
        statusToSet = diary.syncStatus ?? SyncStatus.updated;
      } else {
        statusToSet = SyncStatus.created; // New local item
      }

      diaryMap[columnSyncStatus] = statusToSet.name;
      diaryMap[columnLastSynced] = DateTime.now().millisecondsSinceEpoch;

      int diaryId = diary.id ?? 0;
      String? effectiveClientTempId = diary.clientTempId;

      // Try to find existing diary by clientTempId if id is not provided
      if (diaryId == 0 && effectiveClientTempId != null) {
        final existingByClientTempId = await txn.query(
          tableDiaries,
          where: '$columnClientTempId = ?',
          whereArgs: [effectiveClientTempId],
        );
        if (existingByClientTempId.isNotEmpty) {
          diaryId = existingByClientTempId.first['id'] as int;
          // Preserve existing serverId if not overridden by current diary model
          if (diary.serverId == null &&
              existingByClientTempId.first[columnServerId] != null) {
            diaryMap[columnServerId] =
                existingByClientTempId.first[columnServerId];
          }
        }
      }
      // Try to find existing diary by serverId if id is not provided and clientTempId didn't match
      if (diaryId == 0 && diary.serverId != null) {
        final existingByServerId = await txn.query(
          tableDiaries,
          where: '$columnServerId = ?',
          whereArgs: [diary.serverId],
        );
        if (existingByServerId.isNotEmpty) {
          diaryId = existingByServerId.first['id'] as int;
          // Preserve existing clientTempId if not overridden
          if (effectiveClientTempId == null &&
              existingByServerId.first[columnClientTempId] != null) {
            effectiveClientTempId =
                existingByServerId.first[columnClientTempId] as String?;
            diaryMap[columnClientTempId] = effectiveClientTempId;
          }
        }
      }

      // If diaryId is still 0, it's a new insert. Otherwise, it's an update.
      if (diaryId == 0) {
        // Remove 'id' if it's null, as SQLite expects it for AUTOINCREMENT
        if (diaryMap['id'] == null) diaryMap.remove('id');
        diaryId = await txn.insert(
          tableDiaries,
          diaryMap,
          conflictAlgorithm:
              ConflictAlgorithm
                  .replace, // Or .ignore if you prefer to handle conflicts manually
        );
      } else {
        await txn.update(
          tableDiaries,
          diaryMap,
          where: 'id = ?',
          whereArgs: [diaryId],
        );
      }

      List<Photo> savedPhotos = [];
      if (diary.photos != null) {
        for (Photo photo in diary.photos!) {
          final photoToSave = photo.copyWith(diaryId: diaryId);
          Photo? savedPhoto;
          if (photoToSave.id == null) {
            Photo? existingPhotoByClientTempId;
            if (photoToSave.clientTempId != null) {
              existingPhotoByClientTempId = await photoDao
                  .getPhotoByClientTempId(photoToSave.clientTempId!);
            }
            if (existingPhotoByClientTempId != null) {
              await photoDao.updatePhoto(
                existingPhotoByClientTempId.copyWith(
                  path: photoToSave.path,
                  caption: photoToSave.caption,
                  diaryId: diaryId,
                ),
              );
              savedPhoto = existingPhotoByClientTempId;
            } else {
              savedPhoto = await photoDao.insertPhoto(photoToSave);
            }
          } else {
            await photoDao.updatePhoto(photoToSave);
            savedPhoto = photoToSave;
          }
          if (savedPhoto != null) {
            savedPhotos.add(savedPhoto);
          }
        }
      }

      final currentPhotoIdsInDb =
          (await photoDao.getPhotosForDiary(
            diaryId,
          )).map((p) => p.id).where((id) => id != null).cast<int>().toList();
      final photosToKeepIds =
          savedPhotos
              .map((p) => p.id)
              .where((id) => id != null)
              .cast<int>()
              .toList();

      for (int idInDb in currentPhotoIdsInDb) {
        // Corrected: for...in loop
        if (!photosToKeepIds.contains(idInDb)) {
          await photoDao.deletePhoto(idInDb);
        }
      }

      return diary.copyWith(
        id: diaryId,
        photos: savedPhotos,
        clientTempId: effectiveClientTempId,
        lastSynced: DateTime.fromMillisecondsSinceEpoch(
          diaryMap[columnLastSynced] as int,
        ),
        syncStatus: statusToSet, // Ensure the model reflects the saved status
      );
    });
  }

  Future<void> markDiariesAsSynced(
    List<String> clientTempIds,
    DateTime syncTimestamp, {
    Map<String, String>? serverIds,
    Transaction? txn,
  }) async {
    final dbOrTxn = txn ?? db;
    final batch =
        (dbOrTxn is Database) ? dbOrTxn.batch() : (txn as Transaction).batch();

    for (String clientTempId in clientTempIds) {
      final String? serverId = serverIds?[clientTempId];
      Map<String, dynamic> updateData = {
        columnLastSynced: syncTimestamp.millisecondsSinceEpoch,
        columnSyncStatus: SyncStatus.synced.name,
      };
      if (serverId != null) {
        updateData[columnServerId] = serverId;
      }
      batch.update(
        tableDiaries,
        updateData,
        where: '$columnClientTempId = ?',
        whereArgs: [clientTempId],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<DiaryModel>> getDiaries({
    bool includeDeleted = false,
    Transaction? txn,
  }) async {
    final dbOrTxn = txn ?? db;
    final maps = await dbOrTxn.query(
      tableDiaries,
      where: includeDeleted ? null : '$columnIsDeleted = 0',
      orderBy: 'date DESC',
    );
    List<DiaryModel> diaries = [];
    for (var map in maps) {
      DiaryModel diary = DiaryModel.fromLocalMap(map);
      if (diary.id != null) {
        final photos = await photoDao.getPhotosForDiary(diary.id!, txn: txn);
        diaries.add(
          diary.copyWith(
            photos: photos,
            photoPaths: photos.map((p) => p.path).toList(),
          ),
        );
      } else {
        diaries.add(diary);
      }
    }
    return diaries;
  }

  Future<DiaryModel?> getDiaryForDate(
    String date, {
    bool includeDeleted = false,
    Transaction? txn,
  }) async {
    final dbOrTxn = txn ?? db;
    final maps = await dbOrTxn.query(
      tableDiaries,
      where: 'date = ?' + (includeDeleted ? '' : ' AND $columnIsDeleted = 0'),
      whereArgs: [date],
    );
    if (maps.isNotEmpty) {
      DiaryModel diary = DiaryModel.fromLocalMap(maps.first);
      if (diary.id != null) {
        final photos = await photoDao.getPhotosForDiary(diary.id!, txn: txn);
        return diary.copyWith(
          photos: photos,
          photoPaths: photos.map((p) => p.path).toList(),
        );
      }
      return diary;
    }
    return null;
  }

  Future<DiaryModel?> getDiaryById(
    int id, {
    bool includeDeleted = false,
    Transaction? txn,
  }) async {
    final dbOrTxn = txn ?? db;
    final maps = await dbOrTxn.query(
      tableDiaries,
      where: 'id = ?' + (includeDeleted ? '' : ' AND $columnIsDeleted = 0'),
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      DiaryModel diary = DiaryModel.fromLocalMap(maps.first);
      if (diary.id != null) {
        final photos = await photoDao.getPhotosForDiary(diary.id!, txn: txn);
        return diary.copyWith(
          photos: photos,
          photoPaths: photos.map((p) => p.path).toList(),
        );
      }
      return diary;
    }
    return null;
  }

  Future<Map<String, dynamic>> searchDiaries(
    String query, {
    int? limit,
    int? offset,
    Transaction? txn, // Added transaction
  }) async {
    final dbOrTxn = txn ?? db; // Use transaction if provided
    final queryLower = query.toLowerCase();
    // Base query for counting total matches
    String countQuery =
        'SELECT COUNT(*) FROM $tableDiaries WHERE (LOWER(title) LIKE ? OR LOWER(content) LIKE ?) AND $columnIsDeleted = 0';
    List<dynamic> countArgs = ['%$queryLower%', '%$queryLower%'];
    final totalCountResult = await dbOrTxn.rawQuery(countQuery, countArgs);
    final totalCount = Sqflite.firstIntValue(totalCountResult) ?? 0;

    // Query for fetching paginated results
    String dataQuery =
        'SELECT * FROM $tableDiaries WHERE (LOWER(title) LIKE ? OR LOWER(content) LIKE ?) AND $columnIsDeleted = 0 ORDER BY date DESC';
    List<dynamic> dataArgs = ['%$queryLower%', '%$queryLower%'];

    if (limit != null) {
      dataQuery += ' LIMIT ?';
      dataArgs.add(limit);
      if (offset != null) {
        dataQuery += ' OFFSET ?';
        dataArgs.add(offset);
      }
    }

    final List<Map<String, dynamic>> diariesMaps = await dbOrTxn.rawQuery(
      dataQuery,
      dataArgs,
    );

    List<DiaryModel> diaries = [];
    for (var map in diariesMaps) {
      DiaryModel diary = DiaryModel.fromLocalMap(map);
      if (diary.id != null) {
        final photos = await photoDao.getPhotosForDiary(
          diary.id!,
          txn: txn,
        ); // Pass transaction
        diaries.add(
          diary.copyWith(
            photos: photos,
            photoPaths: photos.map((p) => p.path).toList(),
          ),
        );
      } else {
        diaries.add(diary); // Should ideally not happen if ID is PK
      }
    }

    return {
      'diaries':
          diaries
              .map((d) => d.toMap())
              .toList(), // Return as List<Map> as per original, though List<DiaryModel> might be better
      'totalCount': totalCount,
    };
  }

  Future<int> deleteDiary(
    int id, {
    bool hardDelete = false,
    Transaction? txn,
  }) async {
    final dbOrTxn = txn ?? db;

    Future<int> _performDelete(dynamic executor) async {
      final transaction = executor is Transaction ? executor : null;
      await photoDao.deletePhotosForDiary(
        id,
        hardDelete: hardDelete,
        txn: transaction,
      );

      if (hardDelete) {
        return await executor.delete(
          tableDiaries,
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        return await executor.update(
          tableDiaries,
          {
            columnIsDeleted: 1,
            columnLastSynced: DateTime.now().millisecondsSinceEpoch,
            columnSyncStatus: SyncStatus.deleted.name,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }

    if (dbOrTxn is Database) {
      return await dbOrTxn.transaction((transaction) async {
        return await _performDelete(transaction);
      });
    } else {
      return await _performDelete(dbOrTxn); // dbOrTxn is already a Transaction
    }
  }

  Future<void> updateDiarySyncStatus(
    int diaryId,
    SyncStatus status,
    DateTime syncTimestamp, {
    String? serverId,
    Transaction? txn,
  }) async {
    final dbOrTxn = txn ?? db;
    Map<String, dynamic> data = {
      columnSyncStatus: status.name,
      columnLastSynced: syncTimestamp.millisecondsSinceEpoch,
    };
    if (serverId != null) {
      data[columnServerId] = serverId;
    }
    await dbOrTxn.update(
      tableDiaries,
      data,
      where: 'id = ?',
      whereArgs: [diaryId],
    );
  }

  Future<DiaryModel?> getDiaryByClientTempId(
    String clientTempId, {
    Transaction? txn,
  }) async {
    final dbOrTxn = txn ?? db;
    final maps = await dbOrTxn.query(
      tableDiaries,
      where: '$columnClientTempId = ?',
      whereArgs: [clientTempId],
    );

    if (maps.isNotEmpty) {
      DiaryModel diaryModel = DiaryModel.fromLocalMap(maps.first);
      if (diaryModel.id != null) {
        final photos = await photoDao.getPhotosForDiary(
          diaryModel.id!,
          txn: txn,
        );
        return diaryModel.copyWith(
          photos: photos,
          photoPaths: photos.map((p) => p.path).toList(),
        );
      }
      return diaryModel;
    }
    return null;
  }

  Future<List<DiaryModel>> getUnsyncedDiaries({
    DateTime? lastSyncTimestamp,
    Transaction? txn,
  }) async {
    final dbOrTxn = txn ?? db;
    String whereClause =
        '($columnSyncStatus != ?) OR '
        '($columnIsDeleted = 1 AND $columnSyncStatus = ?)';
    List<dynamic> whereArgs = [SyncStatus.synced.name, SyncStatus.deleted.name];

    if (lastSyncTimestamp != null) {
      whereClause =
          '(($columnSyncStatus != ?) AND ($columnLastSynced IS NULL OR $columnLastSynced > ?)) OR '
          '($columnIsDeleted = 1 AND $columnSyncStatus = ?)';
      whereArgs = [
        SyncStatus.synced.name,
        lastSyncTimestamp.millisecondsSinceEpoch,
        SyncStatus.deleted.name,
      ];
    }

    final maps = await dbOrTxn.query(
      tableDiaries,
      where: whereClause,
      whereArgs: whereArgs,
    );

    List<DiaryModel> diaries = [];
    for (var map in maps) {
      DiaryModel diary = DiaryModel.fromLocalMap(map);
      if (diary.id != null) {
        final photos = await photoDao.getPhotosForDiary(diary.id!, txn: txn);
        diaries.add(diary.copyWith(photos: photos));
      } else {
        diaries.add(diary);
      }
    }
    return diaries;
  }

  Future<void> applyDiarySyncChanges(
    List<DiaryModel> serverItems, {
    Transaction? txn,
  }) async {
    if (txn != null) {
      await _applyChangesInternal(serverItems, txn);
    } else {
      await db.transaction((transaction) async {
        await _applyChangesInternal(serverItems, transaction);
      });
    }
  }

  Future<void> _applyChangesInternal(
    List<DiaryModel> serverItems,
    Transaction executor,
  ) async {
    for (DiaryModel serverDiary in serverItems) {
      if (serverDiary.serverId == null) {
        print(
          "Skipping diary sync: serverId is null for clientTempId ${serverDiary.clientTempId}",
        );
        continue;
      }

      DiaryModel? localVersion = await getDiaryByServerId(
        serverDiary.serverId!,
        txn: executor,
        includeDeleted: true,
      );

      if (serverDiary.isDeleted) {
        if (localVersion != null && localVersion.id != null) {
          await deleteDiary(localVersion.id!, hardDelete: true, txn: executor);
        }
      } else {
        DiaryModel diaryToSave = serverDiary.copyWith(
          syncStatus: SyncStatus.synced,
          lastSynced: DateTime.now(),
        );

        int currentDiaryId;
        if (localVersion != null && localVersion.id != null) {
          currentDiaryId = localVersion.id!;
          diaryToSave = diaryToSave.copyWith(
            id: currentDiaryId,
            clientTempId: localVersion.clientTempId ?? serverDiary.clientTempId,
          );
          await executor.update(
            tableDiaries,
            diaryToSave.toMapWithoutPhotos(),
            where: 'id = ?',
            whereArgs: [currentDiaryId],
          );
        } else {
          Map<String, dynamic> diaryMap = diaryToSave.toMapWithoutPhotos();
          if (diaryMap['id'] == null) diaryMap.remove('id');
          currentDiaryId = await executor.insert(
            tableDiaries,
            diaryMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          diaryToSave = diaryToSave.copyWith(id: currentDiaryId);
        }

        // Prepare photos with the correct local diaryId before calling applyPhotoSyncChanges
        if (serverDiary.photos != null) {
          List<Photo> photosToSync =
              serverDiary.photos!
                  .map((p) => p.copyWith(diaryId: currentDiaryId))
                  .toList();
          await photoDao.applyPhotoSyncChanges(photosToSync, txn: executor);
        }
      }
    }
  }

  Future<DiaryModel?> getDiaryByServerId(
    String serverId, {
    Transaction? txn,
    bool includeDeleted = false,
  }) async {
    final dbOrTxn = txn ?? db;
    final maps = await dbOrTxn.query(
      tableDiaries,
      where:
          '$columnServerId = ?' +
          (includeDeleted ? '' : ' AND $columnIsDeleted = 0'),
      whereArgs: [serverId],
    );

    if (maps.isNotEmpty) {
      DiaryModel diary = DiaryModel.fromLocalMap(maps.first);
      if (diary.id != null) {
        final photos = await photoDao.getPhotosForDiary(diary.id!, txn: txn);
        return diary.copyWith(
          photos: photos,
          photoPaths: photos.map((p) => p.path).toList(),
        );
      }
      return diary;
    }
    return null;
  }

  Future<bool> hasUnsyncedChanges({Transaction? txn}) async {
    final dbOrTxn = txn ?? db;
    String whereClause =
        '($columnSyncStatus != ?) OR '
        '($columnIsDeleted = 1 AND $columnSyncStatus = ?)';
    List<dynamic> whereArgs = [SyncStatus.synced.name, SyncStatus.deleted.name];

    final result = await dbOrTxn.query(
      tableDiaries,
      columns: ['COUNT(*) as count'],
      where: whereClause,
      whereArgs: whereArgs,
    );
    final count = Sqflite.firstIntValue(result);
    return count != null && count > 0;
  }

  Future<void> importDiaries(
    List<Map<String, dynamic>> diariesData,
    DateTime syncTime, {
    Transaction? txn,
  }) async {
    final dbOrTxn = txn ?? db;

    Future<void> _import(dynamic executor) async {
      final batch =
          (executor is Database)
              ? executor.batch()
              : (executor as Transaction).batch();
      for (final diaryMapData in diariesData) {
        DiaryModel diary = DiaryModel.fromJson(
          diaryMapData,
        ); // Convert map to DiaryModel

        Map<String, dynamic> diaryMapForDb = diary.toMapWithoutPhotos();
        diaryMapForDb[columnSyncStatus] = SyncStatus.synced.name;
        diaryMapForDb[columnLastSynced] = syncTime.millisecondsSinceEpoch;

        if (diary.serverId != null) {
          diaryMapForDb[columnServerId] = diary.serverId;
        }
        if (diary.clientTempId != null) {
          diaryMapForDb[columnClientTempId] = diary.clientTempId;
        }

        // Check if a diary with the same serverId or clientTempId exists
        final existingDiaries = await executor.query(
          tableDiaries,
          where: '($columnServerId = ? OR $columnClientTempId = ?)',
          whereArgs: [diary.serverId, diary.clientTempId],
        );

        if (existingDiaries.isNotEmpty) {
          // Update existing diary
          await executor.update(
            tableDiaries,
            diaryMapForDb,
            where: 'id = ?',
            whereArgs: [existingDiaries.first['id']],
          );
        } else {
          // Insert new diary
          await executor.insert(
            tableDiaries,
            diaryMapForDb,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      await batch.commit(noResult: true);
    }

    if (dbOrTxn is Database) {
      await _import(dbOrTxn);
    } else {
      await db.transaction((transaction) async {
        await _import(transaction);
      });
    }
  }
}
