import 'crop_type.dart';
import 'disease_type.dart';

class DiagnosisResult {
  const DiagnosisResult({
    required this.id,
    required this.crop,
    required this.disease,
    required this.rawDiseaseLabel,
    required this.confidence,
    required this.imagePath,
    required this.createdAt,
    required this.isOffline,
    this.recommendation,
    this.recommendationKey,
    this.severity,
    this.actions = const [],
    this.likelyDiseases = const [],
  });

  final String id;
  final CropType crop;

  /// May be null if the backend returned a label not yet in [DiseaseType].
  final DiseaseType? disease;

  /// Always-available raw label string (e.g. "tomato_late_blight").
  final String rawDiseaseLabel;
  final double confidence;
  final String imagePath;
  final DateTime createdAt;
  final bool isOffline;

  /// Full recommendation text (from backend or local strings).
  final String? recommendation;

  /// Legacy key for local string lookup (used offline).
  final String? recommendationKey;
  final String? severity;
  final List<String> actions;
  final List<LikelyDiagnosis> likelyDiseases;

  bool get isHealthy =>
      disease == DiseaseType.healthy || rawDiseaseLabel == 'healthy';
}

class LikelyDiagnosis {
  const LikelyDiagnosis({
    required this.label,
    required this.confidence,
  });

  final String label;
  final double confidence;
}
