// database_helper.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:recap_today/model/freezed/diary_model.dart';
import 'package:recap_today/model/freezed/checklist_item.dart';
import 'package:recap_today/model/freezed/app_usage_model.dart';
import 'package:recap_today/model/freezed/schedule_item.dart';
import 'package:recap_today/model/freezed/emotion_model.dart';
import 'package:recap_today/model/freezed/location_model.dart';
import 'package:recap_today/model/freezed/step_model.dart';
import 'package:recap_today/data/abstract_database.dart';
import 'dart:convert';
import 'package:recap_today/model/freezed/ai_feedback_model.dart';

/// SQLite 데이터베이스 관리를 위한 헬퍼 클래스
/// 모델 데이터의 영구 저장소 역할
class DatabaseHelper implements AbstractDatabase {
  // 싱글톤 패턴 구현
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // 로컬 사용자 ID
  static const String LOCAL_USER_ID = 'local_user';

  // 테이블 이름 상수 정의
  static const String tableUsers = 'users';
  static const String tableChecklist = 'checklist_items';
  static const String tableDiaries = 'diaries';
  static const String tablePhotos = 'photos';
  static const String tableAppUsage = 'app_usage';
  static const String tableSchedule = 'schedule_items';
  static const String tableLocationLogs = 'location_logs';
  static const String tableEmotionRecords = 'emotion_records';
  static const String tableSteps = 'steps';
  static const String tableAiFeedback = 'ai_feedback'; // 새 테이블 추가

  // 프라이빗 생성자
  DatabaseHelper._init();

  /// 데이터베이스 인스턴스 가져오기 (지연 초기화)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('recap_today.db');
    return _database!;
  }

  /// 데이터베이스 초기화
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 14, // 버전을 13에서 14로 증가
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: _configureDB,
    );
  }

  /// 데이터베이스 외래키 제약조건 활성화
  Future _configureDB(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// 데이터베이스 테이블 생성
  Future _createDB(Database db, int version) async {
    // 일기 테이블 생성 (Freezed 모델 지원)
    await db.execute('''
      CREATE TABLE $tableDiaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT,
        photo_paths TEXT,
        user_id TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        UNIQUE(date, user_id)
      )
    ''');

    // 사진 테이블 생성 (일기와 1:N 관계)
    await db.execute('''
      CREATE TABLE $tablePhotos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diary_id INTEGER NOT NULL,
        path TEXT NOT NULL,
        user_id TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (diary_id) REFERENCES $tableDiaries (id) ON DELETE CASCADE
      )
    ''');

    // 체크리스트 아이템 테이블 생성 (Freezed 모델 지원)
    await db.execute('''
      CREATE TABLE $tableChecklist (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        subtext TEXT,
        is_checked INTEGER NOT NULL DEFAULT 0,
        due_date TEXT,
        completed_date TEXT,
        user_id TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 앱 사용 기록 테이블 생성 (Freezed 모델 지원)
    await db.execute('''
      CREATE TABLE $tableAppUsage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        package_name TEXT NOT NULL,
        app_name TEXT NOT NULL,
        usage_time INTEGER NOT NULL,
        app_icon_path TEXT,
        user_id TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 일정 테이블 생성 (Freezed 모델 지원)
    await db.execute('''
      CREATE TABLE $tableSchedule (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        sub_text TEXT,
        day_of_week INTEGER,
        selected_date TEXT,
        is_routine INTEGER NOT NULL,
        start_time_hour INTEGER NOT NULL,
        start_time_minute INTEGER NOT NULL,
        end_time_hour INTEGER NOT NULL,
        end_time_minute INTEGER NOT NULL,
        color_value INTEGER,
        has_alarm INTEGER DEFAULT 0,
        alarm_offset_in_minutes INTEGER,
        user_id TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 감정 기록 테이블 생성 (Freezed 모델 지원)
    await db.execute('''
      CREATE TABLE $tableEmotionRecords (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        hour INTEGER NOT NULL,
        emotion_type TEXT NOT NULL,
        notes TEXT,
        user_id TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        UNIQUE (date, hour, user_id)
      )
    ''');

    // 위치 로그 테이블 생성 (Freezed 모델 지원)
    await db.execute('''
      CREATE TABLE $tableLocationLogs (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL,
        address TEXT,
        timestamp TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 걸음 수 테이블 생성
    await db.execute('''
      CREATE TABLE $tableSteps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        step_count INTEGER NOT NULL,
        distance REAL,
        calories REAL,
        user_id TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        UNIQUE (date, user_id)
      )
    ''');

    // AI 피드백 테이블 생성
    await db.execute('''
      CREATE TABLE $tableAiFeedback (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        feedback_text TEXT NOT NULL,
        user_id TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// 데이터베이스 업그레이드 (스키마 마이그레이션)
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // 기존 버전 업그레이드 처리
    if (oldVersion < 2) {
      // 버전 2로 업그레이드: 체크리스트 테이블에 dueDate 필드 추가
      await db.execute('''
        ALTER TABLE $tableChecklist
        ADD COLUMN due_date TEXT
      ''');
    }
    if (oldVersion < 3) {
      // 버전 3으로 업그레이드: 체크리스트 테이블에 completedDate 필드 추가
      await db.execute('''
        ALTER TABLE $tableChecklist
        ADD COLUMN completed_date TEXT
      ''');
    }
    if (oldVersion < 4) {
      // 버전 4로 업그레이드: 앱 사용 기록 테이블 추가
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableAppUsage (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          package_name TEXT NOT NULL,
          app_name TEXT NOT NULL,
          usage_time INTEGER NOT NULL,
          app_icon_path TEXT
        )
      ''');
    }
    if (oldVersion < 5) {
      // 버전 5로 업그레이드: 일정 테이블 추가
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableSchedule (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          startTime TEXT NOT NULL,
          endTime TEXT NOT NULL,
          date TEXT NOT NULL,
          isCompleted INTEGER NOT NULL DEFAULT 0,
          notificationId INTEGER
        )
      ''');
    }
    // For versions < 8, ensure the emotion_records table is correctly created.
    // This block handles upgrades from any version < 8.
    if (oldVersion < 8) {
      // Updated to check against new version 8
      // To be absolutely sure, we can try dropping it first if it exists,
      // then recreating. This will clear existing emotion data if the schema was wrong.
      // Use with caution if data preservation is critical and the schema was subtly wrong.
      // await db.execute('DROP TABLE IF EXISTS $tableEmotionRecords'); // Uncomment if desperate
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableEmotionRecords (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          hour INTEGER NOT NULL,
          emotionType TEXT NOT NULL,
          notes TEXT,
          UNIQUE (date, hour)
        )
      ''');

      // 위치 로그 테이블 추가
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableLocationLogs (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 9) {
      // 버전 9로 업그레이드: 동기화 대기열 테이블 추가
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pending_sync_locations (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          timestamp TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    // 버전 10 업그레이드: Freezed 모델을 위한 테이블 업데이트
    if (oldVersion < 10) {
      // 사용자 테이블 생성 (새로운 테이블)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableUsers (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          is_synced INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 11) {
      // 버전 번호는 적절히 조정
      // 기존 diaries 테이블에 photo_paths 컬럼 추가
      try {
        await db.execute(
          'ALTER TABLE $tableDiaries ADD COLUMN photo_paths TEXT',
        );

        // 기존 사진 데이터를 마이그레이션
        final diaries = await db.query(tableDiaries);
        for (final diary in diaries) {
          final diaryId = diary['id'] as int;
          final photos = await db.query(
            tablePhotos,
            columns: ['path'],
            where: 'diary_id = ?',
            whereArgs: [diaryId],
          );

          final photoPaths = photos.map((p) => p['path'] as String).toList();
          await db.update(
            tableDiaries,
            {'photo_paths': jsonEncode(photoPaths)},
            where: 'id = ?',
            whereArgs: [diaryId],
          );
        }
      } catch (e) {
        debugPrint('사진 경로 마이그레이션 오류: $e');
      }
    }

    if (oldVersion < 12) {
      // 버전 12로 업그레이드: AI 피드백 테이블 추가
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableAiFeedback (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          feedback_text TEXT NOT NULL,
          user_id TEXT NOT NULL,
          is_synced INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 13) {
      // 버전 13으로 업그레이드: location_logs 테이블에 accuracy, address 컬럼 추가
      await db.execute('''
        ALTER TABLE $tableLocationLogs ADD COLUMN accuracy REAL
      ''');
      await db.execute('''
        ALTER TABLE $tableLocationLogs ADD COLUMN address TEXT
      ''');
    }

    if (oldVersion < 14) {
      // 버전 14로 업그레이드: steps 테이블에 distance, calories 컬럼 추가
      await db.execute('''
        ALTER TABLE $tableSteps ADD COLUMN distance REAL
      ''');
      await db.execute('''
        ALTER TABLE $tableSteps ADD COLUMN calories REAL
      ''');
    }
  }

  /// 데이터베이스 종료
  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // CRUD 메소드 - 일기 (Diary)

  /// 새 일기 추가
  Future<int> insertDiary(DiaryModel diary) async {
    final db = await database;

    // 1. 일기 정보 저장
    final diaryId = await db.insert(tableDiaries, {
      'date': diary.date,
      'title': diary.title,
      'content': diary.content,
      'user_id': diary.userId,
      'is_synced': diary.isSynced ? 1 : 0,
      'photo_paths': jsonEncode(diary.photoPaths),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    return diaryId;
  }

  /// 날짜별 일기 조회
  Future<DiaryModel?> getDiaryByDate(String date, String userId) async {
    final db = await database;
    final maps = await db.query(
      tableDiaries,
      where: 'date = ? AND user_id = ?',
      whereArgs: [date, userId],
    );

    if (maps.isEmpty) return null;
    return DiaryModelX.fromMap(maps.first);
  }

  /// 모든 일기 조회
  Future<List<DiaryModel>> getAllDiaries(String userId) async {
    final db = await database;
    final result = await db.query(
      tableDiaries,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return result.map((json) => DiaryModelX.fromMap(json)).toList();
  }

  /// 일기 업데이트
  Future<int> updateDiary(DiaryModel diary) async {
    final db = await database;
    return await db.update(
      tableDiaries,
      diary.toMap(),
      where: 'id = ?',
      whereArgs: [diary.id],
    );
  }

  /// 일기 삭제
  Future<int> deleteDiary(int id, String userId) async {
    final db = await database;
    return await db.delete(
      tableDiaries,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  /// 일기 검색 (제목 또는 내용 포함, 날짜 최신순 정렬)
  Future<Map<String, dynamic>> searchDiaries(
    String query,
    String userId, {
    int? limit,
    int? offset,
  }) async {
    final db = await database;

    // Include userId in where clause for proper filtering
    String whereClause = '(title LIKE ? OR content LIKE ?) AND user_id = ?';
    List<dynamic> whereArgs = ['%$query%', '%$query%', userId];

    // Get total count for pagination
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) FROM $tableDiaries WHERE $whereClause',
      whereArgs,
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

    final maps = await db.query(
      tableDiaries,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );

    // Convert to diary models
    final diaries = maps.map((json) => DiaryModelX.fromMap(json)).toList();

    // Load photos more efficiently with a single JOIN query
    for (var diary in diaries) {
      if (diary.id != null) {
        final photoPaths = await getPhotosByDiaryId(diary.id!);
        // Use copyWith from Freezed model to add photo paths
        diary = diary.copyWith(photoPaths: photoPaths);
      }
    }

    return {'diaries': diaries, 'totalCount': totalCount};
  }

  /// CRUD 메소드 - 체크리스트 (Checklist)

  /// 새 체크리스트 아이템 추가
  Future<int> insertChecklistItem(ChecklistItem item) async {
    final db = await database;
    return await db.insert(
      tableChecklist,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 모든 체크리스트 아이템 조회
  Future<List<ChecklistItem>> getAllChecklistItems(String userId) async {
    final db = await database;
    final result = await db.query(
      tableChecklist,
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return result.map((json) => ChecklistItemX.fromMap(json)).toList();
  }

  /// 체크리스트 아이템 업데이트
  Future<int> updateChecklistItem(ChecklistItem item) async {
    final db = await database;
    return await db.update(
      tableChecklist,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// 체크리스트 아이템 삭제
  Future<int> deleteChecklistItem(String id, String userId) async {
    final db = await database;
    return await db.delete(
      tableChecklist,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  /// 여러 체크리스트 아이템을 일괄 저장 (배치 처리)
  Future<void> saveChecklistItems(List<ChecklistItem> items) async {
    if (items.isEmpty) return;

    final db = await database;
    final batch = db.batch();

    for (var item in items) {
      batch.insert(
        tableChecklist,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// 특정 날짜에 완료된 체크리스트 아이템 조회
  Future<List<ChecklistItem>> getChecklistItemsByCompletedDate(
    String date,
    String userId,
  ) async {
    final db = await database;
    final result = await db.query(
      tableChecklist,
      where: 'completed_date LIKE ? AND user_id = ?',
      whereArgs: ['$date%', userId], // date로 시작하는 날짜 (yyyy-MM-dd 형식)
    );

    return result.map((json) => ChecklistItemX.fromMap(json)).toList();
  }

  /// 완료되지 않은 모든 체크리스트 아이템 조회
  Future<List<ChecklistItem>> getIncompleteChecklistItems(String userId) async {
    final db = await database;
    final result = await db.query(
      tableChecklist,
      where: 'is_checked = ? AND user_id = ?',
      whereArgs: [0, userId],
    );

    return result.map((json) => ChecklistItemX.fromMap(json)).toList();
  }

  /// 완료된 모든 체크리스트 아이템 조회
  Future<List<ChecklistItem>> getCompletedChecklistItems(String userId) async {
    final db = await database;
    final result = await db.query(
      tableChecklist,
      where: 'is_checked = ? AND user_id = ?',
      whereArgs: [1, userId],
    );

    return result.map((json) => ChecklistItemX.fromMap(json)).toList();
  }

  // CRUD 메소드 - 앱 사용량 (AppUsage)

  /// 앱 사용 기록 추가
  Future<int> insertAppUsage(AppUsageModel appUsage) async {
    final db = await database;
    return await db.insert(
      tableAppUsage,
      appUsage.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 특정 날짜의 앱 사용 기록 조회
  Future<List<AppUsageModel>> getAppUsageByDate(
    String date,
    String userId,
  ) async {
    final db = await database;
    final result = await db.query(
      tableAppUsage,
      where: 'date = ? AND user_id = ?',
      whereArgs: [date, userId],
    );

    return result.map((json) => AppUsageModelX.fromMap(json)).toList();
  }

  /// 앱 사용 기록 삭제 (일자별)
  Future<int> deleteAppUsageByDate(String date, String userId) async {
    final db = await database;
    return await db.delete(
      tableAppUsage,
      where: 'date = ? AND user_id = ?',
      whereArgs: [date, userId],
    );
  }

  /// 앱 사용기록 일괄 삽입 (트랜잭션 사용)
  Future<int> insertAppUsageBatch(
    List<AppUsageModel> appUsages,
    String userId,
  ) async {
    if (appUsages.isEmpty) return 0;

    final db = await instance.database;
    int count = 0;

    try {
      await db.transaction((txn) async {
        Batch batch = txn.batch();

        for (var appUsage in appUsages) {
          batch.insert(tableAppUsage, {
            'date': appUsage.date,
            'package_name': appUsage.packageName,
            'app_name': appUsage.appName,
            'usage_time': appUsage.usageTimeInMillis,
            'app_icon_path': appUsage.appIconPath,
            'user_id': userId,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        await batch.commit(noResult: true);
        count = appUsages.length;
      });

      return count;
    } catch (e) {
      debugPrint('앱 사용 기록 일괄 삽입 중 오류: $e');
      return 0; // 오류 발생 시 0 반환
    }
  }

  // CRUD 메소드 - 일정 (Schedule)

  /// 일정 추가
  Future<int> insertScheduleItem(ScheduleItem item) async {
    final db = await database;
    return await db.insert(
      tableSchedule,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 특정 날짜의 일정 조회
  Future<List<ScheduleItem>> getScheduleItemsByDate(
    String date,
    String userId,
  ) async {
    final db = await database;
    final result = await db.query(
      tableSchedule,
      where: 'selected_date = ? AND user_id = ?',
      whereArgs: [date, userId],
    );

    return result.map((json) => ScheduleItemX.fromMap(json)).toList();
  }

  /// 모든 일정 조회
  Future<List<ScheduleItem>> getAllScheduleItems(String userId) async {
    final db = await database;
    final result = await db.query(
      tableSchedule,
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    debugPrint('데이터베이스에서 로드된 일정: ${result.length}개');
    for (var row in result) {
      debugPrint('일정 데이터: $row');
    }

    return result.map((json) => ScheduleItemX.fromMap(json)).toList();
  }

  /// 일정 업데이트
  Future<int> updateScheduleItem(ScheduleItem item) async {
    final db = await database;
    return await db.update(
      tableSchedule,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// 일정 삭제
  Future<int> deleteScheduleItem(String id, String userId) async {
    final db = await database;
    return await db.delete(
      tableSchedule,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  // CRUD 메소드 - 감정 기록 (Emotion)

  /// 감정 기록 추가
  Future<int> insertEmotionRecord(EmotionRecord emotion) async {
    final db = await database;
    return await db.insert(
      tableEmotionRecords,
      emotion.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 특정 날짜의 감정 기록 조회
  Future<List<EmotionRecord>> getEmotionsByDate(
    String date,
    String userId,
  ) async {
    final db = await database;
    final result = await db.query(
      tableEmotionRecords,
      where: 'date = ? AND user_id = ?',
      whereArgs: [date, userId],
    );

    return result.map((json) => EmotionRecordX.fromMap(json)).toList();
  }

  /// 특정 시간의 감정 기록 조회
  Future<EmotionRecord?> getEmotionByDateAndHour(
    String date,
    int hour,
    String userId,
  ) async {
    final db = await database;
    final result = await db.query(
      tableEmotionRecords,
      where: 'date = ? AND hour = ? AND user_id = ?',
      whereArgs: [date, hour, userId],
    );

    if (result.isEmpty) return null;
    return EmotionRecordX.fromMap(result.first);
  }

  /// 감정 기록 업데이트
  Future<int> updateEmotionRecord(EmotionRecord emotion) async {
    final db = await database;
    return await db.update(
      tableEmotionRecords,
      emotion.toMap(),
      where: 'id = ?',
      whereArgs: [emotion.id],
    );
  }

  Future<int> deleteEmotionRecord(String id, String userId) async {
    final db = await database;
    return await db.delete(
      tableEmotionRecords,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  // CRUD 메소드 - 위치 로그 (Location)

  /// 위치 데이터 삽입
  Future<int> insertLocationLog(Map<String, dynamic> locationLog) async {
    try {
      final db = await instance.database;
      return await db.insert(
        tableLocationLogs,
        locationLog,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('위치 로그 삽입 중 오류 발생: $e');
      rethrow;
    }
  }

  /// 특정 사용자의 특정 날짜 위치 데이터 조회
  Future<List<Map<String, dynamic>>> getLocationLogsForUserAndDate(
    String userId,
    String date,
  ) async {
    try {
      final db = await instance.database;

      // 해당 날짜의 시작과 끝 시간 계산
      final startOfDay = '${date}T00:00:00';
      final endOfDay = '${date}T23:59:59';

      final result = await db.query(
        tableLocationLogs,
        where: 'user_id = ? AND timestamp >= ? AND timestamp <= ?',
        whereArgs: [userId, startOfDay, endOfDay],
        orderBy: 'timestamp ASC',
      );

      return result;
    } catch (e) {
      debugPrint('특정 날짜 위치 로그 조회 중 오류 발생: $e');
      return [];
    }
  }

  /// 특정 사용자의 모든 위치 데이터 조회
  Future<List<Map<String, dynamic>>> getLocationLogsForUser(
    String userId,
  ) async {
    try {
      final db = await instance.database;
      final result = await db.query(
        tableLocationLogs,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
        limit: 100, // 최근 100개만 조회
      );

      return result;
    } catch (e) {
      debugPrint('사용자 위치 로그 조회 중 오류 발생: $e');
      return [];
    }
  }

  /// 특정 사용자의 모든 위치 데이터 조회 (제한 없음)
  Future<List<Map<String, dynamic>>> getAllLocationLogsForUser(
    String userId,
  ) async {
    try {
      final db = await instance.database;
      final result = await db.query(
        tableLocationLogs,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'timestamp ASC',
      );

      return result;
    } catch (e) {
      debugPrint('사용자 전체 위치 로그 조회 중 오류 발생: $e');
      return [];
    }
  }

  /// 특정 사용자의 모든 위치 데이터 삭제
  Future<int> deleteAllLocationLogsForUser(String userId) async {
    try {
      final db = await instance.database;
      return await db.delete(
        tableLocationLogs,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      debugPrint('사용자 위치 로그 전체 삭제 중 오류 발생: $e');
      return 0;
    }
  }

  /// 특정 사용자의 날짜 범위 위치 데이터 조회
  Future<List<Map<String, dynamic>>> getLocationLogsForUserInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final db = await instance.database;
      final startTime = start.toIso8601String();
      final endTime = end.toIso8601String();

      final result = await db.query(
        tableLocationLogs,
        where: 'user_id = ? AND timestamp >= ? AND timestamp <= ?',
        whereArgs: [userId, startTime, endTime],
        orderBy: 'timestamp ASC',
      );

      return result;
    } catch (e) {
      debugPrint('날짜 범위 위치 로그 조회 중 오류 발생: $e');
      return [];
    }
  }

  /// 특정 사용자의 날짜 범위 위치 데이터 삭제
  Future<int> deleteLocationLogsInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final db = await instance.database;
      final startTime = start.toIso8601String();
      final endTime = end.toIso8601String();

      return await db.delete(
        tableLocationLogs,
        where: 'user_id = ? AND timestamp >= ? AND timestamp <= ?',
        whereArgs: [userId, startTime, endTime],
      );
    } catch (e) {
      debugPrint('날짜 범위 위치 로그 삭제 중 오류 발생: $e');
      return 0;
    }
  }

  // CRUD 메소드 - 걸음 수 (Steps)

  /// 걸음 수 기록 추가
  Future<int> insertStepCount(StepModel step) async {
    final db = await database;
    return await db.insert(
      tableSteps,
      step.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 특정 날짜의 걸음 수 조회
  Future<StepModel?> getStepsByDate(String date, String userId) async {
    final db = await database;
    final result = await db.query(
      tableSteps,
      where: 'date = ? AND user_id = ?',
      whereArgs: [date, userId],
    );

    if (result.isEmpty) return null;
    return StepModelX.fromMap(result.first);
  }

  // 사진 관련 메소드

  /// 일기에 사진 추가
  Future<int> insertPhoto(int diaryId, String path, String userId) async {
    final db = await database;
    return await db.insert(tablePhotos, {
      'diary_id': diaryId,
      'path': path,
      'user_id': userId,
      'is_synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 일기의 사진들 조회
  Future<List<String>> getPhotosByDiaryId(int diaryId) async {
    final db = await database;
    final result = await db.query(
      tablePhotos,
      columns: ['path'],
      where: 'diary_id = ?',
      whereArgs: [diaryId],
    );

    return result.map((map) => map['path'] as String).toList();
  }

  /// 사진 삭제
  Future<int> deletePhoto(int id, String userId) async {
    final db = await database;
    return await db.delete(
      tablePhotos,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  /// 일기에 연결된 모든 사진 삭제
  Future<int> deleteAllPhotosForDiary(int diaryId, String userId) async {
    final db = await database;
    return await db.delete(
      tablePhotos,
      where: 'diary_id = ? AND user_id = ?',
      whereArgs: [diaryId, userId],
    );
  }

  /// 동기화 상태 업데이트 (모든 데이터 유형에 공통)
  Future<int> updateSyncStatus(String table, dynamic id, bool isSynced) async {
    final db = await database;
    return await db.update(
      table,
      {'is_synced': isSynced ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 동기화되지 않은 항목 조회
  Future<List<Map<String, dynamic>>> getUnsyncedItems(String table) async {
    final db = await database;
    return await db.query(table, where: 'is_synced = ?', whereArgs: [0]);
  }

  // 마이그레이션(로컬 데이터를 특정 사용자 ID로 마이그레이션) -> 로그인 후 처리
  Future<bool> migrateLocalDataToUser(String userId) async {
    final db = await database;

    try {
      await db.transaction((txn) async {
        final tables = [
          tableDiaries,
          tablePhotos,
          tableChecklist,
          tableAppUsage,
          tableSchedule,
          tableEmotionRecords,
          tableLocationLogs,
          tableSteps,
        ];

        for (final table in tables) {
          await txn.update(
            table,
            {'user_id': userId, 'is_synced': 0},
            where: 'user_id = ?',
            whereArgs: [LOCAL_USER_ID],
          );
        }
      });

      return true;
    } catch (e) {
      debugPrint('로컬 데이터 마이그레이션 중 오류 발생: $e');
      return false;
    }
  }

  // CRUD 메소드 - AI 피드백 (AiFeedback)

  /// AI 피드백 추가
  Future<int> insertAiFeedback(AiFeedbackModel feedback) async {
    final db = await database;
    return await db.insert(
      tableAiFeedback,
      feedback.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 특정 날짜의 AI 피드백 조회
  Future<List<AiFeedbackModel>> getAiFeedbackByDate(
    String date,
    String userId,
  ) async {
    final db = await database;
    final result = await db.query(
      tableAiFeedback,
      where: 'date = ? AND user_id = ?',
      whereArgs: [date, userId],
    );

    return result.map((json) => AiFeedbackModelX.fromMap(json)).toList();
  }

  /// 특정 ID의 AI 피드백 조회
  Future<AiFeedbackModel?> getAiFeedbackById(int id, String userId) async {
    final db = await database;
    final result = await db.query(
      tableAiFeedback,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    if (result.isEmpty) return null;
    return AiFeedbackModelX.fromMap(result.first);
  }

  /// 모든 AI 피드백 조회
  Future<List<AiFeedbackModel>> getAllAiFeedback(String userId) async {
    final db = await database;
    final result = await db.query(
      tableAiFeedback,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return result.map((json) => AiFeedbackModelX.fromMap(json)).toList();
  }

  /// AI 피드백 업데이트
  Future<int> updateAiFeedback(AiFeedbackModel feedback) async {
    final db = await database;
    return await db.update(
      tableAiFeedback,
      feedback.toMap(),
      where: 'id = ?',
      whereArgs: [feedback.id],
    );
  }

  /// AI 피드백 삭제
  Future<int> deleteAiFeedback(int id, String userId) async {
    final db = await database;
    return await db.delete(
      tableAiFeedback,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }
}
