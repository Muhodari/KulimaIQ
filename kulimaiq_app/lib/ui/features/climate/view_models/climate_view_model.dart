import 'package:flutter/foundation.dart';

import '../../../../data/repositories/climate_repository.dart';
import '../../../../data/repositories/farm_repository.dart';
import '../../../../domain/models/climate_advisory.dart';
import '../../../../l10n/app_strings.dart';

class ClimateViewModel extends ChangeNotifier {
  ClimateViewModel({
    required ClimateRepository climateRepository,
    required FarmRepository farmRepository,
    required AppStrings strings,
  })  : _climateRepository = climateRepository,
        _farmRepository = farmRepository,
        _strings = strings;

  final ClimateRepository _climateRepository;
  final FarmRepository _farmRepository;
  AppStrings _strings;

  AppStrings get strings => _strings;

  List<ClimateAdvisory> _advisories = [];
  bool _loading = true;
  bool _isOnline = true;
  bool _noLocations = false;
  String? _error;

  List<ClimateAdvisory> get advisories => _advisories;
  bool get loading => _loading;
  bool get isOnline => _isOnline;

  /// True when the user has no farms with GPS coordinates yet.
  bool get noLocations => _noLocations;
  String? get error => _error;

  void refreshStrings(AppStrings strings) {
    _strings = strings;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    _noLocations = false;
    notifyListeners();

    try {
      _isOnline = await _climateRepository.isOnline();

      // Build location list from farms that have GPS coordinates.
      final farms = await _farmRepository.getFarms();
      final locations = farms
          .where((f) => f.hasCoordinates)
          .map((f) => ClimateLocation(
                label: f.name +
                    (f.locationDisplay.isNotEmpty
                        ? ', ${f.locationDisplay}'
                        : ''),
                latitude: f.latitude!,
                longitude: f.longitude!,
              ))
          .toList();

      if (locations.isEmpty) {
        _noLocations = true;
        _advisories = [];
      } else {
        _advisories = await _climateRepository.getAdvisories(locations);
      }
    } catch (_) {
      _error = _strings.t('error_generic');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
