import 'package:recap_today/model/sync_status.dart';
import 'package:recap_today/model/weather_data.dart';
import 'package:sqflite/sqflite.dart';

class WeatherDao {
  final Database _db;
  static const String tableName = 'weather';

  WeatherDao(this._db);

  Future<void> initTable(Transaction txn) async {
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientTempId TEXT UNIQUE NOT NULL,
        serverId TEXT UNIQUE,
        date TEXT NOT NULL,
        city TEXT NOT NULL,
        country TEXT NOT NULL,
        temperatureCelcius REAL NOT NULL,
        condition TEXT NOT NULL,
        iconUrl TEXT NOT NULL,
        windSpeedKph REAL NOT NULL,
        humidityPercent INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        syncStatus TEXT NOT NULL,
        lastSynced TEXT
      )
    ''');
    await txn.execute(
      'CREATE INDEX IF NOT EXISTS idx_weather_date ON $tableName (date);',
    );
    await txn.execute(
      'CREATE INDEX IF NOT EXISTS idx_weather_client_temp_id ON $tableName (clientTempId);',
    );
    await txn.execute(
      'CREATE INDEX IF NOT EXISTS idx_weather_server_id ON $tableName (serverId);',
    );
    await txn.execute(
      'CREATE INDEX IF NOT EXISTS idx_weather_sync_status ON $tableName (syncStatus);',
    );
  }

  Future<int> insertWeatherData(WeatherData data, {Transaction? txn}) async {
    final dbClient = txn ?? _db;
    return await dbClient.insert(
      tableName,
      data
          .copyWith(syncStatus: SyncStatus.created, updatedAt: DateTime.now())
          .toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<WeatherData?> getWeatherDataByDate(
    DateTime date, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      tableName,
      where: 'date = ?',
      whereArgs: [
        date.toIso8601String().substring(0, 10),
      ], // Compare only date part
    );
    if (maps.isNotEmpty) {
      return WeatherData.fromMap(maps.first);
    }
    return null;
  }

  Future<List<WeatherData>> getWeatherDataForDateRange(
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
    return maps.map((map) => WeatherData.fromMap(map)).toList();
  }

  Future<int> updateWeatherData(WeatherData data, {Transaction? txn}) async {
    final dbClient = txn ?? _db;
    SyncStatus newSyncStatus = data.syncStatus;
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

  Future<int> deleteWeatherData(int id, {Transaction? txn}) async {
    // Hard delete. Consider soft delete for sync.
    final dbClient = txn ?? _db;
    return await dbClient.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Sync methods
  Future<WeatherData?> getWeatherDataByClientTempId(
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
      return WeatherData.fromMap(maps.first);
    }
    return null;
  }

  Future<WeatherData?> getWeatherDataByServerId(
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
      return WeatherData.fromMap(maps.first);
    }
    return null;
  }

  Future<List<WeatherData>> getUnsyncedWeatherData({Transaction? txn}) async {
    final dbClient = txn ?? _db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      tableName,
      where: 'syncStatus != ? AND syncStatus != ?',
      whereArgs: [SyncStatus.synced.name, SyncStatus.deleted.name],
      orderBy: 'updatedAt ASC',
    );
    return maps.map((map) => WeatherData.fromMap(map)).toList();
  }

  Future<void> markWeatherDataAsSynced(
    List<Map<String, String>> clientServerIdMap,
    DateTime lastSynced, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    final batch = dbClient.batch();
    for (var idPair in clientServerIdMap) {
      batch.update(
        tableName,
        {
          'syncStatus': SyncStatus.synced.name,
          'serverId': idPair['serverId']!,
          'lastSynced': lastSynced.toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'clientTempId = ?',
        whereArgs: [idPair['clientTempId']!],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> applyWeatherDataSyncChanges(
    List<WeatherData> serverDataList, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    final batch = dbClient.batch();
    final DateTime syncTime = DateTime.now();

    for (var serverData in serverDataList) {
      WeatherData? localData;
      if (serverData.serverId != null && serverData.serverId!.isNotEmpty) {
        localData = await getWeatherDataByServerId(
          serverData.serverId!,
          txn: txn,
        );
      }
      localData ??= await getWeatherDataByClientTempId(
        serverData.clientTempId,
        txn: txn,
      );

      if (localData != null) {
        if (serverData.syncStatus == SyncStatus.deleted) {
          batch.delete(tableName, where: 'id = ?', whereArgs: [localData.id]);
        } else if (serverData.updatedAt.isAfter(localData.updatedAt) ||
            localData.syncStatus != SyncStatus.synced) {
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
        batch.insert(
          tableName,
          serverData
              .copyWith(syncStatus: SyncStatus.synced, lastSynced: syncTime)
              .toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateWeatherServerIdAndMarkSynced(
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
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'clientTempId = ?',
      whereArgs: [clientTempId],
    );
  }

  Future<int> softDeleteWeatherDataByClientTempId(
    String clientTempId, {
    Transaction? txn,
  }) async {
    final dbClient = txn ?? _db;
    final existing = await getWeatherDataByClientTempId(clientTempId, txn: txn);
    if (existing != null && existing.syncStatus != SyncStatus.deleted) {
      return await dbClient.update(
        tableName,
        {
          'syncStatus': SyncStatus.deleted.name,
          'updatedAt': DateTime.now().toIso8601String(),
          'serverId': existing.serverId,
        },
        where: 'clientTempId = ?',
        whereArgs: [clientTempId],
      );
    }
    return 0;
  }

  Future<int> hardDeleteWeatherDataByClientTempId(
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

  Future<int> hardDeleteWeatherDataByServerId(
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

  Future<void> clearAllWeatherData({Transaction? txn}) async {
    final dbClient = txn ?? _db;
    await dbClient.delete(tableName);
  }
}
