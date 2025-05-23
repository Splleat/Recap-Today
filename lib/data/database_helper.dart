// database_helper.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:recap_today/model/diary_model.dart';
import 'package:recap_today/model/photo_model.dart';
import 'package:recap_today/model/checklist_item.dart';
import 'package:recap_today/model/app_usage_model.dart';
import 'package:recap_today/model/schedule_item.dart'; // 추가된 import

/// SQLite 데이터베이스 관리를 위한 헬퍼 클래스
/// 일기와 체크리스트 항목의 영구 저장소 역할
class DatabaseHelper {
  // 싱글톤 패턴 구현
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // 테이블 이름 상수 정의
  static const String tableChecklist = 'checklist_items';
  static const String tableDiaries = 'diaries';
  static const String tablePhotos = 'photos';
  static const String tableAppUsage = 'app_usage';
  static const String tableSchedule = 'schedule_items'; // 새로운 테이블 이름
  static const String tableEmotionRecords =
      'emotion_records'; // 감정 기록 테이블 이름 직접 정의

  // 프라이빗 생성자
  DatabaseHelper._init();

  /// 데이터베이스 인스턴스 가져오기 (지연 초기화)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('diary.db');
    return _database!;
  }

  /// 데이터베이스 초기화
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 8, // Incremented version to 8
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
    // 일기 테이블 생성
    await db.execute('''
      CREATE TABLE $tableDiaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        content TEXT
      )
    ''');

    // 사진 테이블 생성 (일기와 1:N 관계)
    await db.execute('''
      CREATE TABLE $tablePhotos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diary_id INTEGER NOT NULL,
        path TEXT NOT NULL,
        FOREIGN KEY (diary_id) REFERENCES $tableDiaries (id) ON DELETE CASCADE
      )
    ''');

    // 체크리스트 아이템 테이블 생성
    await db.execute('''
      CREATE TABLE $tableChecklist (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        subtext TEXT,
        isChecked INTEGER NOT NULL DEFAULT 0,
        dueDate TEXT,
        completedDate TEXT
      )
    ''');

    // 앱 사용 기록 테이블 생성
    await db.execute('''
      CREATE TABLE $tableAppUsage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        package_name TEXT NOT NULL,
        app_name TEXT NOT NULL,
        usage_time INTEGER NOT NULL,
        app_icon_path TEXT
      )
    ''');

    // 일정 테이블 생성
    await db.execute('''
      CREATE TABLE $tableSchedule (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        date TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        notificationId INTEGER
      )
    ''');

    // 감정 기록 테이블 생성 (ensure it's also correct in onCreate)
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
  }

  /// 데이터베이스 업그레이드 (스키마 마이그레이션)
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 버전 2로 업그레이드: 체크리스트 테이블에 dueDate 필드 추가
      await db.execute('''
        ALTER TABLE $tableChecklist
        ADD COLUMN dueDate TEXT
      ''');
    }
    if (oldVersion < 3) {
      // 버전 3으로 업그레이드: 체크리스트 테이블에 completedDate 필드 추가
      await db.execute('''
        ALTER TABLE $tableChecklist
        ADD COLUMN completedDate TEXT
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
    }
  }

  /// 일기 삽입
  Future<int> insertDiary(DiaryModel diary) async {
    try {
      final db = await instance.database;
      return await db.insert(
        tableDiaries,
        diary.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error inserting diary: $e');
      rethrow;
    }
  }

  /// 일기 업데이트
  Future<int> updateDiary(DiaryModel diary) async {
    try {
      final db = await instance.database;
      return await db.update(
        tableDiaries,
        diary.toMap(),
        where: 'id = ?',
        whereArgs: [diary.id],
      );
    } catch (e) {
      debugPrint('Error updating diary: $e');
      rethrow;
    }
  }

  /// 일기 목록 가져오기
  Future<List<DiaryModel>> getDiaries() async {
    final db = await instance.database;
    final maps = await db.query('diaries', orderBy: 'date DESC');
    final diaries = List.generate(
      maps.length,
      (i) => DiaryModel.fromMap(maps[i]),
    );

    // 각 일기에 대한 사진 경로 로드
    for (var i = 0; i < diaries.length; i++) {
      if (diaries[i].id != null) {
        final photos = await getPhotosForDiary(diaries[i].id!);
        final paths = photos.map((photo) => photo.path).toList();
        diaries[i] = DiaryModel(
          id: diaries[i].id,
          date: diaries[i].date,
          title: diaries[i].title,
          content: diaries[i].content,
          photoPaths: paths,
        );
      }
    }

    return diaries;
  }

  /// 특정 날짜의 일기 가져오기
  Future<DiaryModel?> getDiaryForDate(String date) async {
    final db = await instance.database;
    final maps = await db.query(
      'diaries',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isNotEmpty) {
      final diary = DiaryModel.fromMap(maps.first);
      if (diary.id != null) {
        final photos = await getPhotosForDiary(diary.id!);
        final paths = photos.map((photo) => photo.path).toList();
        return DiaryModel(
          id: diary.id,
          date: diary.date,
          title: diary.title,
          content: diary.content,
          photoPaths: paths,
        );
      }
      return diary;
    }
    return null;
  }

  /// 일기 검색 (제목 또는 내용 포함, 날짜 최신순 정렬)
  Future<Map<String, dynamic>> searchDiaries(
    String query, {
    int? limit,
    int? offset,
  }) async {
    final db = await instance.database;
    String whereClause = 'title LIKE ? OR content LIKE ?';
    List<dynamic> whereArgs = ['%$query%', '%$query%'];

    // Get total count for pagination
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) FROM $tableDiaries WHERE $whereClause',
      whereArgs,
    );
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

    String orderBy = 'date DESC';
    String? limitClause = limit != null ? 'LIMIT $limit' : null;
    String? offsetClause = offset != null ? 'OFFSET $offset' : null;

    final maps = await db.query(
      tableDiaries,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    final diaries = List.generate(
      maps.length,
      (i) => DiaryModel.fromMap(maps[i]),
    );

    // 각 일기에 대한 사진 경로 로드
    for (var i = 0; i < diaries.length; i++) {
      if (diaries[i].id != null) {
        final photos = await getPhotosForDiary(diaries[i].id!);
        final paths = photos.map((photo) => photo.path).toList();
        diaries[i] = DiaryModel(
          id: diaries[i].id,
          date: diaries[i].date,
          title: diaries[i].title,
          content: diaries[i].content,
          photoPaths: paths,
        );
      }
    }
    return {'diaries': diaries, 'totalCount': totalCount};
  }

  /// 사진 삽입
  Future<int> insertPhoto(Photo photo) async {
    final db = await instance.database;
    return await db.insert('photos', photo.toMap());
  }

  /// 특정 일기의 사진 목록 가져오기
  Future<List<Photo>> getPhotosForDiary(int diaryId) async {
    final db = await instance.database;
    final maps = await db.query(
      'photos',
      where: 'diary_id = ?',
      whereArgs: [diaryId],
    );
    return List.generate(maps.length, (i) => Photo.fromMap(maps[i]));
  }

  /// 특정 일기의 모든 사진 삭제
  Future<int> deletePhotosForDiary(int diaryId) async {
    final db = await instance.database;
    return await db.delete(
      'photos',
      where: 'diary_id = ?',
      whereArgs: [diaryId],
    );
  }

  /// 체크리스트 아이템 일괄 저장 (트랜잭션 사용)
  Future<void> saveChecklistItems(List<ChecklistItem> items) async {
    final db = await instance.database;

    try {
      await db.transaction((txn) async {
        // 전체 삭제 후 다시 저장
        await txn.delete(tableChecklist);

        // 배치 삽입으로 변경
        Batch batch = txn.batch();
        for (final item in items) {
          batch.insert(
            tableChecklist,
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      debugPrint('Error saving checklist items in batch: $e');
      rethrow;
    }
  }

  /// 체크리스트 아이템 삽입
  Future<int> insertChecklistItem(ChecklistItem item) async {
    try {
      final db = await instance.database;
      return await db.insert(
        tableChecklist,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error inserting checklist item: $e');
      rethrow;
    }
  }

  /// 체크리스트 아이템 업데이트
  Future<int> updateChecklistItem(ChecklistItem item) async {
    try {
      final db = await instance.database;
      return await db.update(
        tableChecklist,
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
    } catch (e) {
      debugPrint('Error updating checklist item: $e');
      rethrow;
    }
  }

  /// 모든 체크리스트 아이템 가져오기
  Future<List<ChecklistItem>> getChecklistItems() async {
    try {
      final db = await instance.database;
      final maps = await db.query(tableChecklist);
      return List.generate(maps.length, (i) => ChecklistItem.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Error getting checklist items: $e');
      return [];
    }
  }

  /// 특정 ID의 체크리스트 아이템 가져오기
  Future<ChecklistItem?> getChecklistItemById(String id) async {
    try {
      final db = await instance.database;
      final maps = await db.query(
        tableChecklist,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return ChecklistItem.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting checklist item by id: $e');
      return null;
    }
  }

  /// 체크리스트 아이템 삭제
  Future<int> deleteChecklistItem(String id) async {
    try {
      final db = await instance.database;
      return await db.delete(tableChecklist, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('Error deleting checklist item: $e');
      rethrow;
    }
  }

  /// 모든 체크리스트 아이템 삭제
  Future<int> deleteAllChecklistItems() async {
    try {
      final db = await instance.database;
      return await db.delete(tableChecklist);
    } catch (e) {
      debugPrint('Error deleting all checklist items: $e');
      rethrow;
    }
  }

  /// 앱 사용기록 삽입
  Future<int> insertAppUsage(AppUsageModel appUsage) async {
    try {
      final db = await instance.database;
      return await db.insert(tableAppUsage, {
        'date': appUsage.date,
        'package_name': appUsage.packageName,
        'app_name': appUsage.appName,
        'usage_time': appUsage.usageTimeInMillis,
        'app_icon_path': appUsage.appIconPath,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('앱 사용 기록 삽입 중 오류: $e');
      return -1; // 오류 발생 시 -1 반환
    }
  }

  /// 앱 사용기록 일괄 삽입 (트랜잭션 사용)
  Future<int> insertAppUsageBatch(List<AppUsageModel> appUsages) async {
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

  /// 특정 날짜의 앱 사용기록 가져오기
  Future<List<AppUsageModel>> getAppUsageForDate(String date) async {
    try {
      final db = await instance.database;
      final maps = await db.query(
        tableAppUsage,
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'usage_time DESC',
        limit: 50, // 최대 50개만 로드하여 메모리 사용 최적화
      );

      return List.generate(maps.length, (i) {
        return AppUsageModel(
          id: maps[i]['id'] as int?,
          date: maps[i]['date'] as String,
          packageName: maps[i]['package_name'] as String,
          appName: maps[i]['app_name'] as String,
          usageTimeInMillis: maps[i]['usage_time'] as int,
          appIconPath: maps[i]['app_icon_path'] as String?,
        );
      });
    } catch (e) {
      debugPrint('특정 날짜 앱 사용 기록 조회 중 오류: $e');
      return [];
    }
  }

  /// 특정 날짜의 앱 사용 요약 정보 가져오기
  Future<AppUsageSummary?> getAppUsageSummaryForDate(String date) async {
    try {
      final db = await instance.database;

      // 1. 총 사용 시간 조회 (최적화)
      final totalUsageResult = await db.rawQuery(
        'SELECT SUM(usage_time) as total FROM $tableAppUsage WHERE date = ?',
        [date],
      );
      final totalUsageTime =
          totalUsageResult.isNotEmpty && totalUsageResult[0]['total'] != null
              ? (totalUsageResult[0]['total'] as int)
              : 0;

      if (totalUsageTime <= 0) {
        return null; // 사용 기록이 없는 경우
      }

      // 2. 상위 3개 앱 조회 (최적화)
      final topAppsResult = await db.query(
        tableAppUsage,
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'usage_time DESC',
        limit: 3, // 상위 3개만 필요
      );

      if (topAppsResult.isEmpty) {
        return null;
      }

      final topApps =
          topAppsResult
              .map(
                (map) => AppUsageModel(
                  id: map['id'] as int?,
                  date: map['date'] as String,
                  packageName: map['package_name'] as String,
                  appName: map['app_name'] as String,
                  usageTimeInMillis: map['usage_time'] as int,
                  appIconPath: map['app_icon_path'] as String?,
                ),
              )
              .toList();

      return AppUsageSummary(
        date: date,
        totalUsageTimeInMillis: totalUsageTime,
        topApps: topApps,
      );
    } catch (e) {
      debugPrint('앱 사용 요약 정보 조회 중 오류: $e');
      return null;
    }
  }

  /// 특정 날짜의 앱 사용기록 삭제
  Future<int> deleteAppUsageForDate(String date) async {
    try {
      final db = await instance.database;
      return await db.delete(
        tableAppUsage,
        where: 'date = ?',
        whereArgs: [date],
      );
    } catch (e) {
      debugPrint('앱 사용 기록 삭제 중 오류: $e');
      return 0; // 오류 발생 시 0 반환
    }
  }

  /// 일정 삽입
  Future<int> insertScheduleItem(ScheduleItem item) async {
    try {
      final db = await instance.database;
      return await db.insert(
        tableSchedule,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('일정 삽입 중 오류 발생: $e');
      rethrow;
    }
  }

  /// 일정 업데이트
  Future<int> updateScheduleItem(ScheduleItem item) async {
    try {
      final db = await instance.database;
      return await db.update(
        tableSchedule,
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
    } catch (e) {
      debugPrint('일정 업데이트 중 오류 발생: $e');
      rethrow;
    }
  }

  /// 모든 일정 조회
  Future<List<ScheduleItem>> getScheduleItems() async {
    try {
      final db = await instance.database;
      final result = await db.query(tableSchedule);
      return result.map((map) => ScheduleItem.fromMap(map)).toList();
    } catch (e) {
      debugPrint('일정 조회 중 오류 발생: $e');
      return [];
    }
  }

  /// 특정 날짜의 일정 조회
  Future<List<ScheduleItem>> getScheduleItemsForDate(DateTime date) async {
    try {
      final db = await instance.database;
      final dateString = date.toIso8601String().substring(
        0,
        10,
      ); // YYYY-MM-DD 형식
      final dayOfWeek =
          date.weekday == 7 ? 0 : date.weekday; // SQLite에서는 일요일이 0

      // 한 번의 쿼리로 특정 날짜의 일회성 일정과 해당 요일의 반복 일정을 함께 조회
      final result = await db.rawQuery(
        '''
        SELECT * FROM $tableSchedule 
        WHERE (selectedDate LIKE ? AND isRoutine = 0)
           OR (dayOfWeek = ? AND isRoutine = 1)
        ORDER BY startTimeHour, startTimeMinute
      ''',
        ['$dateString%', dayOfWeek],
      );

      return result.map((map) => ScheduleItem.fromMap(map)).toList();
    } catch (e) {
      debugPrint('특정 날짜 일정 조회 중 오류 발생: $e');
      return [];
    }
  }

  /// 특정 기간의 일정 조회 (캘린더 뷰용)
  Future<List<ScheduleItem>> getScheduleItemsForRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final db = await instance.database;
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);

      // 1. 해당 기간 내의 일회성 일정 조회
      final nonRoutineResult = await db.query(
        tableSchedule,
        where: 'selectedDate >= ? AND selectedDate <= ? AND isRoutine = 0',
        whereArgs: [startStr, endStr],
      );

      // 2. 모든 반복 일정 조회 (날짜 범위 내 요일에 해당하는 일정은 UI에서 필터링)
      final routineResult = await db.query(
        tableSchedule,
        where: 'isRoutine = 1',
      );

      // 두 결과 병합
      final List<ScheduleItem> items = [];
      items.addAll(nonRoutineResult.map((map) => ScheduleItem.fromMap(map)));
      items.addAll(routineResult.map((map) => ScheduleItem.fromMap(map)));

      return items;
    } catch (e) {
      debugPrint('기간 내 일정 조회 중 오류 발생: $e');
      return [];
    }
  }

  /// 특정 월의 일정이 있는 날짜 목록 조회 (캘린더 마커용)
  Future<List<DateTime>> getScheduleDatesForMonth(int year, int month) async {
    try {
      final db = await instance.database;

      // 월 시작일과 종료일 계산
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // 다음 달의 0일 = 현재 달의 마지막 날

      final startStr = startDate.toIso8601String().substring(0, 10);
      final endStr = endDate.toIso8601String().substring(0, 10);

      // 해당 월에 일정이 있는 날짜만 조회
      final result = await db.rawQuery(
        '''
        SELECT DISTINCT substr(selectedDate, 1, 10) as date 
        FROM $tableSchedule 
        WHERE selectedDate >= ? AND selectedDate <= ? AND isRoutine = 0
      ''',
        [startStr, endStr],
      );

      // 결과를 DateTime 리스트로 변환
      final List<DateTime> dates = [];
      for (final row in result) {
        if (row['date'] != null) {
          try {
            dates.add(DateTime.parse(row['date'] as String));
          } catch (e) {
            debugPrint('날짜 변환 오류: $e');
          }
        }
      }

      return dates;
    } catch (e) {
      debugPrint('월간 일정 날짜 조회 중 오류 발생: $e');
      return [];
    }
  }

  /// 일정이 존재하는지 확인
  Future<bool> hasSchedule() async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableSchedule',
      );

      final count = Sqflite.firstIntValue(result) ?? 0;
      return count > 0;
    } catch (e) {
      debugPrint('일정 존재 여부 확인 중 오류 발생: $e');
      return false;
    }
  }

  /// 특정 기간 내 모든 일정 삭제
  Future<int> deleteScheduleItemsInRange(DateTime start, DateTime end) async {
    try {
      final db = await instance.database;
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);

      return await db.delete(
        tableSchedule,
        where: 'selectedDate >= ? AND selectedDate <= ? AND isRoutine = 0',
        whereArgs: [startStr, endStr],
      );
    } catch (e) {
      debugPrint('기간 내 일정 삭제 중 오류 발생: $e');
      rethrow;
    }
  }

  /// 일정 데이터 일괄 저장 (트랜잭션 사용)
  Future<void> saveScheduleItems(List<ScheduleItem> items) async {
    try {
      final db = await instance.database;

      await db.transaction((txn) async {
        // 전체 삭제 대신 개별 저장 또는 업데이트
        Batch batch = txn.batch();

        for (final item in items) {
          // 각 항목 삽입 또는 업데이트 (REPLACE 전략)
          batch.insert(
            tableSchedule,
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit(noResult: true);
      });
    } catch (e) {
      debugPrint('일정 일괄 저장 중 오류 발생: $e');
      rethrow;
    }
  }

  /// 반복 일정만 조회
  Future<List<ScheduleItem>> getRoutineScheduleItems() async {
    try {
      final db = await instance.database;
      final result = await db.query(
        tableSchedule,
        where: 'isRoutine = ?',
        whereArgs: [1], // 1은 루틴 일정
      );
      return result.map((map) => ScheduleItem.fromMap(map)).toList();
    } catch (e) {
      debugPrint('반복 일정 조회 중 오류 발생: $e');
      return [];
    }
  }

  /// 특정 ID의 일정 조회
  Future<ScheduleItem?> getScheduleItemById(String id) async {
    try {
      final db = await instance.database;
      final result = await db.query(
        tableSchedule,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isNotEmpty) {
        return ScheduleItem.fromMap(result.first);
      }
      return null;
    } catch (e) {
      debugPrint('특정 ID 일정 조회 중 오류 발생: $e');
      return null;
    }
  }

  /// 일정 삭제
  Future<int> deleteScheduleItem(String id) async {
    try {
      final db = await instance.database;
      return await db.delete(tableSchedule, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('일정 삭제 중 오류 발생: $e');
      rethrow;
    }
  }

  /// 모든 일정 삭제
  Future<int> deleteAllScheduleItems() async {
    try {
      final db = await instance.database;
      return await db.delete(tableSchedule);
    } catch (e) {
      debugPrint('모든 일정 삭제 중 오류 발생: $e');
      rethrow;
    }
  }
}
