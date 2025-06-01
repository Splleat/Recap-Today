// database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:recap_today/data/dao/schedule_dao.dart';
import 'package:recap_today/data/dao/diary_dao.dart';
import 'package:recap_today/data/dao/checklist_dao.dart';
import 'package:recap_today/data/dao/app_usage_dao.dart';
import 'package:recap_today/data/dao/emotion_dao.dart';
import 'package:recap_today/data/dao/location_dao.dart';
// import 'package:recap_today/data/dao/pedometer_dao.dart'; // Commented out
// import 'package:recap_today/data/dao/weather_dao.dart'; // Commented out
import 'package:recap_today/data/dao/photo_dao.dart';

/// SQLite 데이터베이스 관리를 위한 헬퍼 클래스
/// 일기와 체크리스트 항목의 영구 저장소 역할
class DatabaseHelper {
  // 싱글톤 패턴 구현
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // 프라이빗 생성자
  DatabaseHelper._init();

  // 데이터베이스 버전 - PedometerData와 WeatherData 테이블 추가로 버전 증가
  static const int _databaseVersion =
      20; // Incremented version for app_settings table

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
      version: _databaseVersion, // Use the incremented version
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
    // Create PhotoDao instance to call its non-static createTable method
    final photoDaoInstance = PhotoDao(db);
    await photoDaoInstance.createTable(db);

    await DiaryDao.createTable(
      db,
    ); // DiaryDao.createTable only creates the diaries table now
    await ChecklistDao.createTable(db); // Corrected: Call static method
    await AppUsageDao.createTable(db);
    await ScheduleDao.createTable(db);
    await EmotionDao.createTable(db);
    await LocationDao(db).createTable();
    // await PedometerDao.createTable(db); // Commented out
    // await WeatherDao.createTable(db); // Commented out
  }

  /// 데이터베이스 업그레이드 (스키마 마이그레이션)
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Create PhotoDao instance to call its non-static upgradeTable method
    final photoDaoInstance = PhotoDao(db);
    await photoDaoInstance.upgradeTable(db, oldVersion, newVersion);

    // Call upgradeTable for all DAOs.
    await DiaryDao.upgradeTable(db, oldVersion, newVersion);
    await ChecklistDao.upgradeTable(
      db,
      oldVersion,
      newVersion,
    ); // Corrected: Call static method
    await AppUsageDao.upgradeTable(db, oldVersion, newVersion);
    await EmotionDao.upgradeTable(db, oldVersion, newVersion);
    await LocationDao(db).upgradeTable(oldVersion, newVersion);
    await ScheduleDao.upgradeTable(db, oldVersion, newVersion);
    // await PhotoDao.upgradeTable(db, oldVersion, newVersion); // This was static, now called via instance above

    // For new tables, call their upgradeTable or createTable(ifNotExists: true)
    // if oldVersion is less than the version they were introduced.
    // Since _databaseVersion is now 18, and these tables are new in this version:
    // if (oldVersion < 18 && newVersion >= 18) { // Commented out Pedometer/Weather logic
    //   await PedometerDao.createTable(db, ifNotExists: true);
    //   await WeatherDao.createTable(db, ifNotExists: true);
    // }
    // Alternatively, if PedometerDao and WeatherDao have their own robust upgradeTable methods:
    // await PedometerDao.upgradeTable(db, oldVersion, newVersion); // Commented out
    // await WeatherDao.upgradeTable(db, oldVersion, newVersion); // Commented out

    // Drop pending_sync_locations table if upgrading from a version less than 19
    if (oldVersion < 19 && newVersion >= 19) {
      await db.execute('DROP TABLE IF EXISTS pending_sync_locations');
    }

    // Create app_settings table if it doesn't exist (needed for lastSyncTime)
    // This should ideally be tied to a specific version upgrade.
    // For simplicity, adding it here to ensure it exists.
    if (oldVersion < 20 && newVersion >= 20) {
      // Assuming version 20 for this change
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
    }
  }

  // DAO 인스턴스화 메서드 (예시)
  // 실제 사용 시에는 Provider 등을 통해 의존성 주입하는 것이 일반적입니다.
  Future<DiaryDao> get diaryDao async => DiaryDao(await database);
  Future<ChecklistDao> get checklistDao async =>
      ChecklistDao(await database); // Corrected instantiation
  Future<AppUsageDao> get appUsageDao async => AppUsageDao(await database);
  Future<EmotionDao> get emotionDao async => EmotionDao(await database);
  Future<LocationDao> get locationDao async => LocationDao(await database);
  Future<ScheduleDao> get scheduleDao async => ScheduleDao(await database);
  // Future<PedometerDao> get pedometerDao async => PedometerDao(await database); // Commented out
  // Future<WeatherDao> get weatherDao async => WeatherDao(await database); // Commented out
  Future<PhotoDao> get photoDao async {
    return PhotoDao(await database);
  }
}
