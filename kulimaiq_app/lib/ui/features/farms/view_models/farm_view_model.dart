import 'package:flutter/foundation.dart';

import '../../../../data/repositories/farm_repository.dart';
import '../../../../data/services/farm_weather_service.dart';
import '../../../../domain/models/crop_type.dart';
import '../../../../domain/models/farm.dart';
import '../../../../domain/models/farm_weather.dart';
import '../../../../l10n/app_strings.dart';

/// Farms grouped by country (sorted alphabetically).
typedef FarmsByCountry = Map<String, List<Farm>>;

class FarmViewModel extends ChangeNotifier {
  FarmViewModel({
    required FarmRepository farmRepository,
    required FarmWeatherService farmWeatherService,
    required AppStrings strings,
  })  : _farmRepository = farmRepository,
        _farmWeatherService = farmWeatherService,
        _strings = strings;

  final FarmRepository _farmRepository;
  final FarmWeatherService _farmWeatherService;
  AppStrings _strings;

  AppStrings get strings => _strings;

  List<Farm> _farms = [];
  double? _overallScore;
  bool _loading = true;
  String? _error;

  /// weather keyed by farm ID — refreshed each time [load] is called.
  final Map<String, FarmWeather> _weatherCache = {};

  List<Farm> get farms => _farms;
  double? get overallScore => _overallScore;
  bool get loading => _loading;
  String? get error => _error;

  int get farmCount => _farms.length;

  int get healthyCount =>
      _farms.where((f) => f.healthStatus == FarmHealthStatus.healthy).length;

  int get atRiskCount => _farms
      .where((f) =>
          f.healthStatus == FarmHealthStatus.atRisk ||
          f.healthStatus == FarmHealthStatus.diseased)
      .length;

  /// Latest weather for a specific farm (null if not yet fetched or offline).
  FarmWeather? weatherFor(String farmId) => _weatherCache[farmId];

  /// Farms grouped by country, sorted alphabetically by country name.
  FarmsByCountry get farmsByCountry {
    final result = <String, List<Farm>>{};
    for (final farm in _farms) {
      final key = farm.country.isNotEmpty ? farm.country : '—';
      result.putIfAbsent(key, () => []).add(farm);
    }
    return Map.fromEntries(
      result.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  /// Countries that have at least one farm.
  List<String> get activeCountries => farmsByCountry.keys.toList();

  void refreshStrings(AppStrings strings) {
    _strings = strings;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _farms = await _farmRepository.getFarms();
      _overallScore = await _farmRepository.getOverallHealthScore();
      // Fetch weather for all farms that have GPS coordinates (fire-and-forget,
      // individual failures are silently swallowed inside the service).
      await _fetchWeatherForAllFarms();
    } catch (_) {
      _error = _strings.t('error_generic');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchWeatherForAllFarms() async {
    final futures = _farms
        .where((f) => f.hasCoordinates)
        .map((f) async {
          final w = await _farmWeatherService.fetchWeather(
            f.latitude!,
            f.longitude!,
          );
          if (w != null) _weatherCache[f.id] = w;
        });
    await Future.wait(futures);
  }

  Future<void> addFarm({
    required String name,
    required String country,
    required String region,
    double? latitude,
    double? longitude,
    required double sizeHa,
    required List<CropType> crops,
    String notes = '',
  }) async {
    final farm = Farm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      country: country.trim(),
      region: region.trim(),
      latitude: latitude,
      longitude: longitude,
      sizeHa: sizeHa,
      crops: crops,
      healthStatus: FarmHealthStatus.unknown,
      lastScannedAt: null,
      createdAt: DateTime.now(),
      notes: notes.trim(),
    );
    await _farmRepository.createFarm(farm);
    await load();
  }

  Future<void> updateFarm(Farm farm) async {
    await _farmRepository.updateFarm(farm);
    await load();
  }

  Future<void> deleteFarm(String id) async {
    await _farmRepository.deleteFarm(id);
    await load();
  }
}
