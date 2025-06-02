import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'recap_today.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE checklist (
        id TEXT PRIMARY KEY,
        userId TEXT,
        text TEXT,
        subtext TEXT,
        isChecked INTEGER,
        dueDate TEXT,
        completedDate TEXT,
        isSynced INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE app_usage (
        id TEXT PRIMARY KEY,
        userId TEXT,
        date TEXT,
        packageName TEXT,
        appName TEXT,
        usageTimeInMillis INTEGER,
        appIconPath TEXT,
        isSynced INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE diary (
        id TEXT PRIMARY KEY,
        userId TEXT,
        date TEXT,
        content TEXT,
        isSynced INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE emotion (
        id TEXT PRIMARY KEY,
        userId TEXT,
        date TEXT,
        emotionType TEXT,
        intensity INTEGER,
        isSynced INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE location (
        id TEXT PRIMARY KEY,
        userId TEXT,
        date TEXT,
        latitude REAL,
        longitude REAL,
        isSynced INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE photo (
        id TEXT PRIMARY KEY,
        userId TEXT,
        date TEXT,
        photoPath TEXT,
        isSynced INTEGER,
        FOREIGN KEY (diaryId) REFERENCES diary(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE schedule (
        id TEXT PRIMARY KEY,
        userId TEXT,
        date TEXT,
        title TEXT,
        description TEXT,
        isCompleted INTEGER,
        isSynced INTEGER
      )
    ''');
  }
}