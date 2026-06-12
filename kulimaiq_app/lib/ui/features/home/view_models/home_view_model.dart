import 'package:flutter/foundation.dart';

import '../../../../data/repositories/diagnosis_repository.dart';
import '../../../../domain/models/diagnosis_result.dart';
import '../../../../l10n/app_strings.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required DiagnosisRepository diagnosisRepository,
    required AppStrings strings,
  })  : _diagnosisRepository = diagnosisRepository,
        _strings = strings;

  final DiagnosisRepository _diagnosisRepository;
  AppStrings _strings;

  AppStrings get strings => _strings;

  List<DiagnosisResult> _recent = [];
  bool _loading = true;
  String? _error;

  List<DiagnosisResult> get recent => _recent;
  bool get loading => _loading;
  String? get error => _error;

  void refreshStrings(AppStrings strings) {
    _strings = strings;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _recent = await _diagnosisRepository.getHistory();
      if (_recent.length > 5) {
        _recent = _recent.take(5).toList();
      }
    } catch (_) {
      _error = _strings.t('error_generic');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
