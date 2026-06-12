import 'package:flutter/foundation.dart';

import '../../data/services/preferences_service.dart';

class AppShellViewModel extends ChangeNotifier {
  AppShellViewModel({required PreferencesService preferencesService})
      : _preferencesService = preferencesService {
    _load();
  }

  final PreferencesService _preferencesService;

  int _tabIndex = 0;
  bool _showOnboarding = true;
  bool _initialized = false;

  int get tabIndex => _tabIndex;
  bool get showOnboarding => _showOnboarding;
  bool get initialized => _initialized;

  Future<void> _load() async {
    final done = await _preferencesService.isOnboardingComplete();
    _showOnboarding = !done;
    _initialized = true;
    notifyListeners();
  }

  void setTab(int index) {
    _tabIndex = index;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await _preferencesService.setOnboardingComplete(true);
    _showOnboarding = false;
    notifyListeners();
  }
}
