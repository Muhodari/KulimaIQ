import 'package:sqflite/sqflite.dart';

import '../../domain/models/crop_type.dart';
import '../../domain/models/disease_type.dart';
import '../../domain/models/farm.dart';
import 'backend_api_service.dart';
import 'database_service.dart';

/// Farm service: backend is the source of truth when online; SQLite is the
/// offline cache so the app still works without a network connection.
class FarmService {
  FarmService({
    required DatabaseService databaseService,
    required BackendApiService backendApiService,
  })  : _databaseService = databaseService,
        _backendApiService = backendApiService;

  final DatabaseService _databaseService;
  final BackendApiService _backendApiService;

  // ── Read ───────────────────────────────────────────────────────────────────

  Future<List<Farm>> getFarms() async {
    // 1. Try backend — sync into local cache, then read from cache.
    //    Any sync error is swallowed so the local cache always loads.
    List<BackendFarm>? remote;
    try {
      remote = await _backendApiService.getFarms();
      if (remote != null) {
        final db = await _databaseService.database;
        await _syncRemoteFarms(db, remote);
      }
    } catch (_) {
      // Sync failure — fall through to local cache.
    }

    // 2. Always read from local SQLite (includes synced + offline-created farms).
    final db = await _databaseService.database;
    final rows = await db.query('farms', orderBy: 'created_at DESC');
    final farms = <Farm>[];
    for (final row in rows) {
      try {
        final score = await _computeHealthScore(db, row['id']! as String);
        farms.add(_fromRow(row, score));
      } catch (_) {
        // Skip rows from older schemas or corrupt cache entries.
      }
    }
    return farms;
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  Future<Farm> createFarm(Farm farm) async {
    Farm toSave = farm;

    // 1. Try backend — if it creates the farm, use its UUID as the canonical ID.
    try {
      final created =
          await _backendApiService.createFarm(_toBackendFarm(farm));
      if (created != null) {
        toSave = _fromBackendFarm(created, null);
      }
    } catch (_) {
      // Network error — fall through to local-only save.
    }

    // 2. Persist locally (replace handles the case where we already saved a
    //    temp record and are now upserting with the backend-assigned UUID).
    final db = await _databaseService.database;
    await _insertFarmRow(db, toSave);
    return toSave;
  }

  Future<void> _insertFarmRow(Database db, Farm farm) async {
    final row = _toRow(farm);
    try {
      await db.insert('farms', row,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } on DatabaseException {
      // Older app versions required a legacy `location` column on farms.
      final legacy = Map<String, Object?>.from(row)..['location'] = farm.name;
      await db.insert('farms', legacy,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  Future<void> updateFarm(Farm farm) async {
    // Update local first for immediate UI feedback.
    final db = await _databaseService.database;
    await db.update('farms', _toRow(farm),
        where: 'id = ?', whereArgs: [farm.id]);

    // Fire-and-forget backend update (errors are silently ignored).
    try {
      _backendApiService.updateFarm(farm.id, _toBackendFarm(farm));
    } catch (_) {}
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  static bool _isServerFarmId(String id) =>
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-').hasMatch(id);

  Future<void> deleteFarm(String id) async {
    final db = await _databaseService.database;
    final existing = await db.query(
      'farms',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (existing.isEmpty) return;

    if (_isServerFarmId(id)) {
      final ok = await _backendApiService.deleteFarm(id);
      if (!ok) {
        throw StateError('delete_failed');
      }
    }

    await db.delete('farms', where: 'id = ?', whereArgs: [id]);
    await db.delete('diagnoses', where: 'farm_id = ?', whereArgs: [id]);
  }

  // ── Sync ───────────────────────────────────────────────────────────────────

  Future<void> _syncRemoteFarms(
      Database db, List<BackendFarm> remote) async {
    if (remote.isEmpty) return;
    final batch = db.batch();
    for (final bf in remote) {
      final farm = _fromBackendFarm(bf, null);
      batch.insert('farms', _toRow(farm),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true, continueOnError: true);
  }

  // ── Health score ───────────────────────────────────────────────────────────

  Future<double?> _computeHealthScore(Database db, String farmId) async {
    final rows = await db.query(
      'diagnoses',
      where: 'farm_id = ?',
      whereArgs: [farmId],
      orderBy: 'created_at DESC',
      limit: 10,
    );
    if (rows.isEmpty) return null;
    double total = 0;
    int counted = 0;
    for (final r in rows) {
      try {
        final disease =
            DiseaseType.fromId(r['disease'] as String?) ?? DiseaseType.healthy;
        final confidence = (r['confidence'] as num).toDouble();
        if (disease == DiseaseType.healthy) {
          total += confidence * 100;
        } else {
          total += (1 - confidence) * 100;
        }
        counted++;
      } catch (_) {
        // Ignore malformed diagnosis rows.
      }
    }
    if (counted == 0) return null;
    return (total / counted).clamp(0, 100);
  }

  // ── Mappers ────────────────────────────────────────────────────────────────

  Farm _fromBackendFarm(BackendFarm bf, double? healthScore) => Farm(
        id: bf.id,
        name: bf.name,
        country: bf.country,
        region: bf.region,
        latitude: bf.latitude,
        longitude: bf.longitude,
        sizeHa: bf.sizeHa,
        crops: bf.crops
            .map(CropType.fromId)
            .whereType<CropType>()
            .toList(),
        healthStatus: FarmHealthStatusX.fromId(bf.healthStatus),
        lastScannedAt: bf.lastScannedAt,
        createdAt: bf.createdAt,
        notes: bf.notes,
        healthScore: healthScore,
      );

  BackendFarm _toBackendFarm(Farm farm) => BackendFarm(
        id: farm.id,
        name: farm.name,
        country: farm.country,
        region: farm.region,
        latitude: farm.latitude,
        longitude: farm.longitude,
        sizeHa: farm.sizeHa,
        crops: farm.crops.map((c) => c.id).toList(),
        healthStatus: farm.healthStatus.id,
        lastScannedAt: farm.lastScannedAt,
        createdAt: farm.createdAt,
        notes: farm.notes,
        healthScore: farm.healthScore,
      );

  Map<String, Object?> _toRow(Farm farm) => {
        'id': farm.id,
        'name': farm.name,
        'country': farm.country,
        'region': farm.region,
        'latitude': farm.latitude,
        'longitude': farm.longitude,
        'size_ha': farm.sizeHa,
        'crops': farm.crops.map((c) => c.id).join(','),
        'health_status': farm.healthStatus.id,
        'last_scanned_at': farm.lastScannedAt?.millisecondsSinceEpoch,
        'created_at': farm.createdAt.millisecondsSinceEpoch,
        'notes': farm.notes,
      };

  Farm _fromRow(Map<String, Object?> row, double? healthScore) {
    final cropsRaw = (row['crops'] as String?) ?? '';
    final crops = cropsRaw.isEmpty
        ? <CropType>[]
        : cropsRaw
            .split(',')
            .map(CropType.fromId)
            .whereType<CropType>()
            .toList();
    final lastScanned = row['last_scanned_at'] as int?;
    return Farm(
      id: row['id']! as String,
      name: row['name']! as String,
      country: (row['country'] as String?) ?? '',
      region: (row['region'] as String?) ?? '',
      latitude: row['latitude'] as double?,
      longitude: row['longitude'] as double?,
      sizeHa: ((row['size_ha'] as num?) ?? 0).toDouble(),
      crops: crops,
      healthStatus: FarmHealthStatusX.fromId(row['health_status'] as String?),
      lastScannedAt: lastScanned != null
          ? DateTime.fromMillisecondsSinceEpoch(lastScanned)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      notes: (row['notes'] as String?) ?? '',
      healthScore: healthScore,
    );
  }
}
