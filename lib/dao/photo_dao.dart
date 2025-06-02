import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class PhotoDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Map<String, dynamic>>> getAllPhotos() async {
    final db = await _dbHelper.database;
    return await db.query('photo');
  }

  Future<int> insertPhoto(Map<String, dynamic> photo) async {
    final db = await _dbHelper.database;
    return await db.insert('photo', photo);
  }

  Future<int> updatePhoto(Map<String, dynamic> photo) async {
    final db = await _dbHelper.database;
    return await db.update('photo', photo, where: 'id = ?', whereArgs: [photo['id']]);
  }

  Future<int> deletePhoto(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('photo', where: 'id = ?', whereArgs: [id]);
  }
}
