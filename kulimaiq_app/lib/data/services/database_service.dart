import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService();

  static const _dbName = 'kulimaiq.db';
  static const _dbVersion = 7;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createCoreTables(db);
    await _createUsersTable(db);
    await _createFarmsTable(db);
    await _addFarmIdToDiagnoses(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createUsersTable(db);
    if (oldVersion < 3) {
      await _createFarmsTable(db);
      await _addFarmIdToDiagnoses(db);
    }
    if (oldVersion < 4) {
      await _addRwandaLocationColumns(db);
    }
    if (oldVersion < 5) {
      await _migrateToGenericLocation(db);
    }
    if (oldVersion < 6) {
      await _addRecommendationColumn(db);
    }
    if (oldVersion < 7) {
      await _addDiagnosisTreatmentColumns(db);
    }
  }

  Future<void> _createCoreTables(Database db) async {
    await db.execute('''
      CREATE TABLE diagnoses (
        id TEXT PRIMARY KEY,
        crop TEXT NOT NULL,
        disease TEXT NOT NULL,
        confidence REAL NOT NULL,
        image_path TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        is_offline INTEGER NOT NULL,
        recommendation_key TEXT,
        recommendation TEXT,
        severity TEXT,
        actions_json TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE farmer_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL,
        sector TEXT NOT NULL,
        province TEXT NOT NULL,
        phone TEXT NOT NULL,
        crops TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        phone TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        display_name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createFarmsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS farms (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        country TEXT NOT NULL DEFAULT '',
        region TEXT NOT NULL DEFAULT '',
        latitude REAL,
        longitude REAL,
        size_ha REAL NOT NULL DEFAULT 0,
        crops TEXT NOT NULL DEFAULT '',
        health_status TEXT NOT NULL DEFAULT 'unknown',
        last_scanned_at INTEGER,
        created_at INTEGER NOT NULL,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  /// v4 (Rwanda-specific columns — kept for upgrade path completeness).
  Future<void> _addRwandaLocationColumns(Database db) async {
    for (final ddl in [
      "ALTER TABLE farms ADD COLUMN province TEXT NOT NULL DEFAULT 'northern'",
      "ALTER TABLE farms ADD COLUMN sector TEXT NOT NULL DEFAULT ''",
      "ALTER TABLE farms ADD COLUMN village TEXT NOT NULL DEFAULT ''",
    ]) {
      try {
        await db.execute(ddl);
      } catch (_) {}
    }
    try {
      await db.execute(
        "UPDATE farms SET sector = location WHERE sector = '' AND location IS NOT NULL AND location != ''",
      );
    } catch (_) {}
  }

  /// v5 migration: replace Rwanda-specific columns with generic country/region
  /// + GPS coordinates. Existing `sector` → `region`, `province` display name
  /// is stored as-is in `country` if present.
  Future<void> _migrateToGenericLocation(Database db) async {
    for (final ddl in [
      "ALTER TABLE farms ADD COLUMN country TEXT NOT NULL DEFAULT ''",
      "ALTER TABLE farms ADD COLUMN region TEXT NOT NULL DEFAULT ''",
      'ALTER TABLE farms ADD COLUMN latitude REAL',
      'ALTER TABLE farms ADD COLUMN longitude REAL',
    ]) {
      try {
        await db.execute(ddl);
      } catch (_) {}
    }
    // Copy sector → region, province display name → country for existing rows.
    try {
      await db.execute(
        "UPDATE farms SET region = sector WHERE region = '' AND sector IS NOT NULL AND sector != ''",
      );
    } catch (_) {}
  }

  Future<void> _addFarmIdToDiagnoses(Database db) async {
    try {
      await db.execute('ALTER TABLE diagnoses ADD COLUMN farm_id TEXT');
    } catch (_) {
      // Column may already exist on fresh installs.
    }
  }

  /// v6: add full recommendation text column so backend text is persisted.
  Future<void> _addRecommendationColumn(Database db) async {
    try {
      await db.execute('ALTER TABLE diagnoses ADD COLUMN recommendation TEXT');
    } catch (_) {}
  }

  /// v7: persist treatment severity and action steps from scan results.
  Future<void> _addDiagnosisTreatmentColumns(Database db) async {
    for (final ddl in [
      'ALTER TABLE diagnoses ADD COLUMN severity TEXT',
      'ALTER TABLE diagnoses ADD COLUMN actions_json TEXT',
    ]) {
      try {
        await db.execute(ddl);
      } catch (_) {}
    }
  }
}
