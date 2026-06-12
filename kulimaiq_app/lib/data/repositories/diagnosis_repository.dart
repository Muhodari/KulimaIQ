import 'package:sqflite/sqflite.dart';

import '../../domain/models/crop_type.dart';
import '../../domain/models/diagnosis_result.dart';
import '../../domain/models/disease_type.dart';
import '../services/backend_api_service.dart';
import '../services/connectivity_service.dart';
import '../services/database_service.dart';
import '../services/disease_inference_service.dart';

class DiagnosisRepository {
  DiagnosisRepository({
    required DatabaseService databaseService,
    required DiseaseInferenceService inferenceService,
    required ConnectivityService connectivityService,
    required BackendApiService backendApiService,
  })  : _databaseService = databaseService,
        _inferenceService = inferenceService,
        _connectivityService = connectivityService,
        _backendApiService = backendApiService;

  final DatabaseService _databaseService;
  final DiseaseInferenceService _inferenceService;
  final ConnectivityService _connectivityService;
  final BackendApiService _backendApiService;

  // ── Diagnose ───────────────────────────────────────────────────────────────

  Future<DiagnosisResult> diagnose({
    required String imagePath,
    required CropType crop,
    String? farmId,
  }) async {
    final output = await _inferenceService.classify(
      imagePath: imagePath,
      crop: crop,
      farmId: farmId,
    );
    final isOffline = !(await _connectivityService.isOnline());

    // Use the backend's UUID as the local ID when available so the same record
    // isn't duplicated (local timestamp ID + remote UUID) when history syncs.
    final id = output.backendDiagnosisId ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final result = DiagnosisResult(
      id: id,
      crop: crop,
      disease: output.disease,
      rawDiseaseLabel: output.rawDiseaseLabel,
      confidence: output.confidence,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      isOffline: isOffline,
      recommendation: output.recommendation,
    );
    await _save(result);
    return result;
  }

  // ── History ────────────────────────────────────────────────────────────────

  /// Returns diagnosis history.
  ///
  /// When online, attempts to fetch from backend and merge into local SQLite.
  /// Any sync error is swallowed — local cache is always returned as fallback.
  Future<List<DiagnosisResult>> getHistory() async {
    final online = await _connectivityService.isOnline();
    if (online) {
      try {
        final remote = await _backendApiService.getDiagnoses();
        if (remote != null) {
          await _syncRemoteDiagnoses(remote);
        }
      } catch (_) {
        // Sync failure must never prevent local history from loading.
      }
    }

    final db = await _databaseService.database;
    final rows = await db.query('diagnoses', orderBy: 'created_at DESC');
    return rows.map(_fromRow).toList();
  }

  /// Returns diagnoses for a specific farm.
  Future<List<DiagnosisResult>> getHistoryForFarm(String farmId) async {
    final online = await _connectivityService.isOnline();
    if (online) {
      try {
        final remote = await _backendApiService.getDiagnoses(farmId: farmId);
        if (remote != null) {
          await _syncRemoteDiagnoses(remote);
        }
      } catch (_) {
        // Sync failure — fall through to local cache.
      }
    }

    final db = await _databaseService.database;
    final rows = await db.query(
      'diagnoses',
      where: 'farm_id = ?',
      whereArgs: [farmId],
      orderBy: 'created_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  // ── Sync ───────────────────────────────────────────────────────────────────

  Future<void> _syncRemoteDiagnoses(List<BackendDiagnosis> remote) async {
    if (remote.isEmpty) return;
    final db = await _databaseService.database;
    final batch = db.batch();
    for (final bd in remote) {
      batch.insert(
        'diagnoses',
        {
          'id': bd.id,
          'crop': bd.crop.isNotEmpty ? bd.crop : 'unknown',
          'disease': bd.disease.isNotEmpty ? bd.disease : 'healthy',
          'confidence': bd.confidence,
          'image_path': '',
          'farm_id': bd.farmId,
          'created_at': bd.createdAt.millisecondsSinceEpoch,
          'is_offline': 0,
          'recommendation': bd.recommendation,
          'recommendation_key': null,
        },
        // IGNORE keeps the local record (with real image path) if already saved.
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true, continueOnError: true);
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _save(DiagnosisResult result) async {
    final db = await _databaseService.database;
    await db.insert(
      'diagnoses',
      {
        'id': result.id,
        'crop': result.crop.id,
        'disease': result.rawDiseaseLabel,
        'confidence': result.confidence,
        'image_path': result.imagePath,
        'farm_id': null,
        'created_at': result.createdAt.millisecondsSinceEpoch,
        'is_offline': result.isOffline ? 1 : 0,
        'recommendation_key': result.recommendationKey,
        'recommendation': result.recommendation,
      },
      // REPLACE so re-scanning the same image (same backend UUID) updates
      // the local record with the real image path instead of throwing.
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  DiagnosisResult _fromRow(Map<String, Object?> row) {
    final rawLabel = (row['disease'] as String?) ?? 'healthy';
    final isOfflineRaw = row['is_offline'];
    final isOffline = isOfflineRaw == null
        ? false
        : (isOfflineRaw is int ? isOfflineRaw == 1 : isOfflineRaw == true);

    return DiagnosisResult(
      id: row['id']! as String,
      crop: CropType.fromId(row['crop'] as String?) ?? CropType.cassava,
      disease: DiseaseType.fromId(rawLabel),
      rawDiseaseLabel: rawLabel,
      confidence: (row['confidence'] as num?)?.toDouble() ?? 0.0,
      imagePath: (row['image_path'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as int?) ?? 0,
      ),
      isOffline: isOffline,
      recommendation: row['recommendation'] as String?,
      recommendationKey: row['recommendation_key'] as String?,
    );
  }
}
