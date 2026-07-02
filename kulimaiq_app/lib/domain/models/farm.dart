import 'crop_type.dart';

enum FarmHealthStatus { healthy, atRisk, diseased, unknown }

extension FarmHealthStatusX on FarmHealthStatus {
  String get id => name;

  static FarmHealthStatus fromId(String? id) {
    for (final s in FarmHealthStatus.values) {
      if (s.id == id) return s;
    }
    return FarmHealthStatus.unknown;
  }
}

class Farm {
  const Farm({
    required this.id,
    required this.name,
    this.country = '',
    this.region = '',
    this.latitude,
    this.longitude,
    required this.sizeHa,
    required this.crops,
    required this.healthStatus,
    required this.lastScannedAt,
    required this.createdAt,
    this.notes = '',
    this.healthScore,
  });

  final String id;
  final String name;

  /// Retained for storage/backend compatibility only — not collected or shown
  /// in the app (KulimaIQ needs no location for disease detection).
  final String country;
  final String region;
  final double? latitude;
  final double? longitude;

  final double sizeHa;
  final List<CropType> crops;
  final FarmHealthStatus healthStatus;
  final DateTime? lastScannedAt;
  final DateTime createdAt;
  final String notes;

  /// 0–100 computed from diagnosis history (null = no scans yet).
  final double? healthScore;

  Farm copyWith({
    String? name,
    double? sizeHa,
    List<CropType>? crops,
    FarmHealthStatus? healthStatus,
    DateTime? lastScannedAt,
    String? notes,
    double? healthScore,
  }) {
    return Farm(
      id: id,
      name: name ?? this.name,
      country: country,
      region: region,
      latitude: latitude,
      longitude: longitude,
      sizeHa: sizeHa ?? this.sizeHa,
      crops: crops ?? this.crops,
      healthStatus: healthStatus ?? this.healthStatus,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      createdAt: createdAt,
      notes: notes ?? this.notes,
      healthScore: healthScore ?? this.healthScore,
    );
  }
}
