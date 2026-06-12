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
    required this.country,
    required this.region,
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

  /// Country where the farm is located (free text, e.g. "Rwanda", "Uganda").
  final String country;

  /// Sub-region / sector / district within the country.
  final String region;

  /// GPS latitude — used to fetch live weather for this farm.
  final double? latitude;

  /// GPS longitude — used to fetch live weather for this farm.
  final double? longitude;

  final double sizeHa;
  final List<CropType> crops;
  final FarmHealthStatus healthStatus;
  final DateTime? lastScannedAt;
  final DateTime createdAt;
  final String notes;

  /// 0–100 computed from diagnosis history (null = no scans yet).
  final double? healthScore;

  bool get hasCoordinates => latitude != null && longitude != null;

  /// Short human-readable location, e.g. "Musanze, Rwanda".
  String get locationDisplay {
    if (region.isNotEmpty && country.isNotEmpty) return '$region, $country';
    if (region.isNotEmpty) return region;
    if (country.isNotEmpty) return country;
    return '';
  }

  Farm copyWith({
    String? name,
    String? country,
    String? region,
    double? latitude,
    double? longitude,
    bool clearCoordinates = false,
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
      country: country ?? this.country,
      region: region ?? this.region,
      latitude: clearCoordinates ? null : (latitude ?? this.latitude),
      longitude: clearCoordinates ? null : (longitude ?? this.longitude),
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
