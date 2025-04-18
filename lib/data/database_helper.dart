// database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:recap_today/model/diary_model.dart';
import 'package:recap_today/model/photo_model.dart';

/// SQLite 데이터베이스 헬퍼 클래스
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// 데이터베이스 인스턴스 가져오기
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('diary.db');
    return _database!;
  }

  /// 데이터베이스 초기화
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  /// 데이터베이스 테이블 생성
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        content TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diary_id INTEGER NOT NULL,
        path TEXT NOT NULL,
        FOREIGN KEY (diary_id) REFERENCES diaries (id)
      )
    ''');
  }

  /// 일기 삽입
  Future<int> insertDiary(DiaryModel diary) async {
    final db = await instance.database;
    return await db.insert(
      'diaries',
      diary.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 일기 업데이트
  Future<int> updateDiary(DiaryModel diary) async {
    final db = await instance.database;
    return await db.update(
      'diaries',
      diary.toMap(),
      where: 'id = ?',
      whereArgs: [diary.id],
    );
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
}
