// database_helper.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:recap_today/model/diary_model.dart';
import 'package:recap_today/model/photo_model.dart';
import 'package:recap_today/model/checklist_item.dart';

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
      version: 2,
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
        dueDate TEXT
      )
    ''');
  }

  /// 데이터베이스 업그레이드 처리
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
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
}
