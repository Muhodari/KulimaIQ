import 'package:flutter/foundation.dart';

import '../../data/services/preferences_service.dart';
import '../../l10n/app_strings.dart';

class LocaleViewModel extends ChangeNotifier {
  LocaleViewModel({required PreferencesService preferencesService})
      : _preferencesService = preferencesService {
    _load();
  }

  final PreferencesService _preferencesService;

  String _locale = 'en';
  String get locale => _locale;

  AppStrings get strings => AppStrings(_locale);

  Future<void> _load() async {
    _locale = await _preferencesService.getLocale();
    notifyListeners();
  }

  Future<void> setLocale(String code) async {
    if (!AppStrings.supportedLocales.contains(code)) return;
    _locale = code;
    await _preferencesService.setLocale(code);
    notifyListeners();
  }
}
