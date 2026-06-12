import '../../domain/models/climate_advisory.dart';
import '../services/climate_api_service.dart';
import '../services/connectivity_service.dart';

/// Represents a single GPS location to fetch advisories for.
class ClimateLocation {
  const ClimateLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final double latitude;
  final double longitude;
}

class ClimateRepository {
  ClimateRepository({
    required ClimateApiService climateApiService,
    required ConnectivityService connectivityService,
  })  : _climateApiService = climateApiService,
        _connectivityService = connectivityService;

  final ClimateApiService _climateApiService;
  final ConnectivityService _connectivityService;

  /// Fetches real weather advisories for [locations].
  ///
  /// Returns an empty list when offline or when no locations are provided.
  Future<List<ClimateAdvisory>> getAdvisories(
      List<ClimateLocation> locations) async {
    if (locations.isEmpty) return [];
    if (!await _connectivityService.isOnline()) return [];

    final results = await Future.wait(
      locations.map(
        (loc) => _climateApiService.fetchAdvisories(
          latitude: loc.latitude,
          longitude: loc.longitude,
          location: loc.label,
        ),
      ),
    );
    return results.expand((list) => list).toList();
  }

  Future<bool> isOnline() => _connectivityService.isOnline();
}
