import 'package:flutter/foundation.dart';

import '../../../../data/repositories/diagnosis_repository.dart';
import '../../../../data/services/farm_advisory_service.dart';
import '../../../../domain/models/diagnosis_result.dart';
import '../../../../domain/models/farm.dart';
import '../../../../domain/models/farm_advisory.dart';
import '../../../../l10n/app_strings.dart';
import '../view_models/farm_view_model.dart';

class FarmDetailViewModel extends ChangeNotifier {
  FarmDetailViewModel({
    required Farm farm,
    required FarmViewModel farmViewModel,
    required DiagnosisRepository diagnosisRepository,
    required FarmAdvisoryService advisoryService,
    required AppStrings strings,
  })  : _farm = farm,
        _farmViewModel = farmViewModel,
        _diagnosisRepository = diagnosisRepository,
        _advisoryService = advisoryService,
        _strings = strings {
    load();
  }

  final FarmViewModel _farmViewModel;
  final DiagnosisRepository _diagnosisRepository;
  final FarmAdvisoryService _advisoryService;
  AppStrings _strings;

  Farm _farm;
  List<DiagnosisResult> _scans = [];
  List<FarmCropSuggestion> _suggestions = [];
  bool _loading = true;
  String? _error;

  Farm get farm => _farm;
  AppStrings get strings => _strings;
  List<DiagnosisResult> get scans => _scans;
  List<FarmCropSuggestion> get suggestions => _suggestions;
  bool get loading => _loading;
  String? get error => _error;

  void refreshStrings(AppStrings strings) => _strings = strings;

  static int _priorityRank(String priority) => switch (priority) {
        'now' => 0,
        'week' => 1,
        _ => 2,
      };

  List<FarmCropSuggestion> _sortSuggestions(List<FarmCropSuggestion> items) {
    final sorted = List<FarmCropSuggestion>.from(items);
    sorted.sort((a, b) {
      final byPriority =
          _priorityRank(a.priority).compareTo(_priorityRank(b.priority));
      if (byPriority != 0) return byPriority;
      return a.cropId.compareTo(b.cropId);
    });
    return sorted;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = _farmViewModel.farms
          .where((f) => f.id == _farm.id)
          .firstOrNull;
      if (updated != null) _farm = updated;

      final scans = await _diagnosisRepository.getHistoryForFarm(_farm.id);
      _scans = scans;
      final bundle = await _advisoryService.buildAdvisories(scans, _strings);
      _suggestions = _sortSuggestions(bundle.suggestions);
    } catch (_) {
      _error = _strings.t('error_generic');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
