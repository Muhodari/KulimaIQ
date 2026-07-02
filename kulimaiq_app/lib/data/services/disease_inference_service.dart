import 'dart:math';

import '../../domain/models/crop_type.dart';
import '../../domain/models/disease_type.dart';
import 'backend_api_service.dart';

/// Disease inference with automatic backend/offline routing.
///
/// Priority:
///   1. KulimaIQ backend API (real MobileNetV2 ML model on the server)
///   2. Local heuristics (offline fallback — demo placeholder only)
class DiseaseInferenceService {
  DiseaseInferenceService({
    BackendApiService? backendApiService,
    Random? random,
  })  : _backendApiService = backendApiService ?? BackendApiService(),
        _random = random ?? Random();

  final BackendApiService _backendApiService;
  final Random _random;

  Future<InferenceOutput> classify({
    required String imagePath,
    required CropType crop,
    String? farmId,
  }) async {
    // ── 1. Try backend ML ───────────────────────────────────────────────────
    final backendResult = await _backendApiService.analyzeImage(
      imagePath: imagePath,
      crop: crop.id,
      farmId: farmId,
    );

    if (backendResult != null) {
      final cropFiltered = _filterProbabilitiesByCrop(
        backendResult.allProbabilities,
        crop.id,
      );
      final likelyDiseases = cropFiltered.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      // The backend returns the exact class label (e.g. "tomato_late_blight").
      // DiseaseType.fromId returns null for labels not yet in the enum —
      // that is fine, we pass null and the UI shows the raw label gracefully.
      final disease = DiseaseType.fromId(backendResult.disease);
      return InferenceOutput(
        disease: disease,
        rawDiseaseLabel: backendResult.disease,
        recommendation: backendResult.recommendation,
        confidence: backendResult.confidence,
        severity: backendResult.severity,
        actions: backendResult.actions,
        likelyDiseases: likelyDiseases
            .take(3)
            .map((e) => LikelyDisease(label: e.key, confidence: e.value))
            .toList(),
        source: InferenceSource.backend,
        backendDiagnosisId: backendResult.diagnosisId,
      );
    }

    // ── 2. Local heuristic fallback (offline / no backend) ─────────────────
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return _inferWithHeuristics(crop);
  }

  // ── Local heuristics (demo / offline) ─────────────────────────────────────

  InferenceOutput _inferWithHeuristics(CropType crop) {
    final diseases = _diseasesForCrop(crop);
    final disease = diseases[_random.nextInt(diseases.length)];
    final confidence = disease == DiseaseType.healthy
        ? 0.82 + _random.nextDouble() * 0.12
        : 0.78 + _random.nextDouble() * 0.17;

    return InferenceOutput(
      disease: disease,
      rawDiseaseLabel: disease?.id ?? 'healthy',
      recommendation: null,   // offline — UI falls back to local strings
      confidence: confidence.clamp(0.0, 0.99),
      severity: null,
      actions: const [],
      likelyDiseases: [
        LikelyDisease(
          label: disease?.id ?? 'healthy',
          confidence: confidence.clamp(0.0, 0.99),
        ),
      ],
      source: InferenceSource.offline,
    );
  }

  /// Returns a small set of diseases for demo / offline fallback.
  List<DiseaseType?> _diseasesForCrop(CropType crop) {
    switch (crop) {
      case CropType.cassava:
        return [DiseaseType.healthy, DiseaseType.cassavaMosaic];
      case CropType.maize:
        return [DiseaseType.healthy, DiseaseType.maizeNecrosis, DiseaseType.maizeCommonRust];
      case CropType.banana:
        return [DiseaseType.healthy, DiseaseType.bananaWilt, DiseaseType.bananaSigatoka];
      case CropType.tomato:
        return [DiseaseType.healthy, DiseaseType.tomatoLateBlight, DiseaseType.tomatoEarlyBlight];
      case CropType.potato:
        return [DiseaseType.healthy, DiseaseType.potatoLateBlight, DiseaseType.potatoEarlyBlight];
      case CropType.bean:
        return [DiseaseType.healthy, DiseaseType.beanAngularSpot, DiseaseType.beanRust];
      case CropType.coffee:
        return [DiseaseType.healthy, DiseaseType.coffeeLeafRust, DiseaseType.coffeeBerryDisease];
      case CropType.rice:
        return [DiseaseType.healthy, DiseaseType.riceBlast, DiseaseType.riceBrownSpot];
      case CropType.sweetPotato:
        return [DiseaseType.healthy, DiseaseType.sweetPotatoVirus];
      case CropType.sorghum:
        return [DiseaseType.healthy, DiseaseType.sorghumLeafBlight];
      case CropType.wheat:
        return [DiseaseType.healthy, DiseaseType.wheatRust, DiseaseType.wheatSeptoria];
      case CropType.groundnut:
        return [DiseaseType.healthy, DiseaseType.groundnutLeafSpot, DiseaseType.groundnutRosette];
      case CropType.soybean:
        return [DiseaseType.healthy, DiseaseType.soybeanRust];
      case CropType.onion:
        return [DiseaseType.healthy, DiseaseType.onionPurpleBlotch];
      case CropType.pepper:
        return [DiseaseType.healthy, DiseaseType.pepperBacterialSpot];
      case CropType.cabbage:
        return [DiseaseType.healthy, DiseaseType.cabbageBlackRot];
      case CropType.mango:
        return [DiseaseType.healthy, DiseaseType.mangoAnthracnose];
      case CropType.apple:
        return [DiseaseType.healthy, DiseaseType.appleScab, DiseaseType.appleBlackRot];
      case CropType.grape:
        return [DiseaseType.healthy, DiseaseType.grapeBlackRot, DiseaseType.grapeEsca];
      case CropType.orange:
        return [DiseaseType.healthy, DiseaseType.citrusGreening];
      default:
        return [DiseaseType.healthy];
    }
  }

  Map<String, double> _filterProbabilitiesByCrop(
    Map<String, double> allProbabilities,
    String cropId,
  ) {
    final filtered = <String, double>{};
    for (final entry in allProbabilities.entries) {
      if (entry.key == 'healthy' || entry.key.startsWith('${cropId}_')) {
        filtered[entry.key] = entry.value;
      }
    }
    if (filtered.isEmpty) {
      return allProbabilities;
    }
    final total = filtered.values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) {
      return filtered;
    }
    return {
      for (final entry in filtered.entries) entry.key: entry.value / total,
    };
  }
}

enum InferenceSource { backend, offline }

class InferenceOutput {
  const InferenceOutput({
    required this.disease,
    required this.rawDiseaseLabel,
    required this.confidence,
    required this.source,
    this.recommendation,
    this.severity,
    this.actions = const [],
    this.likelyDiseases = const [],
    this.backendDiagnosisId,
  });

  /// Known disease enum value, or null if the backend returned an unrecognised label.
  final DiseaseType? disease;

  /// The exact label string from the backend / heuristic (always non-null).
  final String rawDiseaseLabel;
  final double confidence;
  final InferenceSource source;

  /// Full recommendation text from the backend, or null when offline.
  final String? recommendation;
  final String? severity;
  final List<String> actions;
  final List<LikelyDisease> likelyDiseases;

  /// MongoDB-assigned ID from the backend. When set, the local record should
  /// reuse this ID so remote and local records stay in sync (no duplicates).
  final String? backendDiagnosisId;

  bool get isFromBackend => source == InferenceSource.backend;

  bool get isHealthy =>
      disease == DiseaseType.healthy || rawDiseaseLabel == 'healthy';
}

class LikelyDisease {
  const LikelyDisease({
    required this.label,
    required this.confidence,
  });

  final String label;
  final double confidence;
}
