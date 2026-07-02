import 'package:flutter/foundation.dart';

import '../../../../data/repositories/farm_repository.dart';
import '../../../../domain/models/crop_type.dart';
import '../../../../domain/models/farm.dart';
import '../../../../l10n/app_strings.dart';

class FarmViewModel extends ChangeNotifier {
  FarmViewModel({
    required FarmRepository farmRepository,
    required AppStrings strings,
  })  : _farmRepository = farmRepository,
        _strings = strings;

  final FarmRepository _farmRepository;
  AppStrings _strings;

  AppStrings get strings => _strings;

  List<Farm> _farms = [];
  double? _overallScore;
  bool _loading = true;
  String? _error;

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

  void refreshStrings(AppStrings strings) {
    _strings = strings;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _refreshFarms();
    } catch (_) {
      _error = _strings.t('error_generic');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshFarms() async {
    _farms = await _farmRepository.getFarms();
    final scored = _farms.where((f) => f.healthScore != null).toList();
    _overallScore = scored.isEmpty
        ? null
        : scored.fold<double>(0, (sum, f) => sum + (f.healthScore ?? 0)) /
            scored.length;
  }

  Future<void> addFarm({
    required String name,
    required double sizeHa,
    required List<CropType> crops,
    String notes = '',
  }) async {
    final farm = Farm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
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
    await _refreshFarms();
    notifyListeners();
  }
}
