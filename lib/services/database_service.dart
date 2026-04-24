import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/emergency_service.dart';
import '../models/emergency_contact.dart';

class DatabaseService {
  static const String _dbName = 'roadsos.db';
  static const int _dbVersion = 2; // Incremented for user_profile

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE user_profile(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          contact TEXT,
          aadhaar TEXT
        )
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE services(
        id TEXT PRIMARY KEY,
        name TEXT,
        type TEXT,
        latitude REAL,
        longitude REAL,
        phoneNumber TEXT,
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE contacts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phoneNumber TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profile(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        contact TEXT,
        aadhaar TEXT
      )
    ''');
  }

  // --- User Profile operations ---
  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    final db = await database;
    await db.insert('user_profile', profile, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user_profile', limit: 1);
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // --- Services operations ---
  Future<void> insertService(EmergencyService service) async {
    final db = await database;
    await db.insert('services', service.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<EmergencyService>> getServices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('services');
    return List.generate(maps.length, (i) => EmergencyService.fromMap(maps[i]));
  }

  Future<void> clearServices() async {
    final db = await database;
    await db.delete('services');
  }

  // --- Contacts operations ---
  Future<void> insertContact(EmergencyContact contact) async {
    final db = await database;
    await db.insert('contacts', contact.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<EmergencyContact>> getContacts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('contacts');
    return List.generate(maps.length, (i) => EmergencyContact.fromMap(maps[i]));
  }

  Future<void> deleteContact(int id) async {
    final db = await database;
    await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }
}
