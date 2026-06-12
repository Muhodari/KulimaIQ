import '../../domain/models/farm.dart';
import '../services/farm_service.dart';

class FarmRepository {
  FarmRepository({required FarmService farmService})
      : _farmService = farmService;

  final FarmService _farmService;

  Future<List<Farm>> getFarms() => _farmService.getFarms();

  Future<Farm> createFarm(Farm farm) => _farmService.createFarm(farm);

  Future<void> updateFarm(Farm farm) => _farmService.updateFarm(farm);

  Future<void> deleteFarm(String id) => _farmService.deleteFarm(id);

  /// Returns a 0–100 overall health score across all farms, or null if no data.
  Future<double?> getOverallHealthScore() async {
    final farms = await getFarms();
    final scored = farms.where((f) => f.healthScore != null).toList();
    if (scored.isEmpty) return null;
    final total =
        scored.fold<double>(0, (sum, f) => sum + (f.healthScore ?? 0));
    return total / scored.length;
  }
}
