// database_helper.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:recap_today/model/diary_model.dart';
import 'package:recap_today/model/photo_model.dart';
import 'package:recap_today/model/checklist_item.dart';
import 'package:recap_today/model/app_usage_model.dart';

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
      version: 4,
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

    // 인덱스 생성
    await db.execute(
      'CREATE INDEX idx_completedDate ON $tableChecklist(completedDate)',
    );
    await db.execute(
      'CREATE INDEX idx_isChecked ON $tableChecklist(isChecked)',
    );
  }

  /// 데이터베이스 업그레이드 처리
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // 버전별 마이그레이션 로직
    if (oldVersion < 2) {
      // 버전 1에서 버전 2로 업그레이드: 체크리스트 테이블 추가
      await db.execute('''
        CREATE TABLE $tableChecklist (
          id TEXT PRIMARY KEY,
          text TEXT NOT NULL,
          subtext TEXT,
          isChecked INTEGER NOT NULL DEFAULT 0,
          dueDate TEXT
        )
      ''');
    }

    if (oldVersion < 3) {
      // 버전 2에서 버전 3으로 업그레이드: 체크리스트 테이블에 completedDate 열 추가
      try {
        await db.execute(
          'ALTER TABLE $tableChecklist ADD COLUMN completedDate TEXT;',
        );
        // 인덱스 생성
        await db.execute(
          'CREATE INDEX idx_completedDate ON $tableChecklist(completedDate)',
        );
        await db.execute(
          'CREATE INDEX idx_isChecked ON $tableChecklist(isChecked)',
        );
      } catch (e) {
        debugPrint('테이블 업그레이드 중 오류 발생: $e');
        // 테이블이 존재하지 않는 경우 새로 생성
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableChecklist (
            id TEXT PRIMARY KEY,
            text TEXT NOT NULL,
            subtext TEXT,
            isChecked INTEGER NOT NULL DEFAULT 0,
            dueDate TEXT,
            completedDate TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_completedDate ON $tableChecklist(completedDate)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_isChecked ON $tableChecklist(isChecked)',
        );
      }
    }

    if (oldVersion < 4) {
      // 버전 3에서 버전 4로 업그레이드: 앱 사용 기록 테이블 추가
      try {
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

        // 인덱스 생성
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_app_usage_date ON $tableAppUsage(date)',
        );
      } catch (e) {
        debugPrint('앱 사용 기록 테이블 생성 중 오류 발생: $e');
      }
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
}
