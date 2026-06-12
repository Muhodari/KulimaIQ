import 'package:flutter/foundation.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/auth_service.dart' show AuthException;
import '../../../../domain/models/auth_user.dart';
import '../../../../l10n/app_strings.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required AuthRepository authRepository,
    required AppStrings strings,
  })  : _authRepository = authRepository,
        _strings = strings;

  final AuthRepository _authRepository;
  AppStrings _strings;

  AppStrings get strings => _strings;

  AuthUser? _user;
  bool _initialized = false;
  bool _loading = false;
  bool _isRegisterMode = false;
  String? _error;

  AuthUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get initialized => _initialized;
  bool get loading => _loading;
  bool get isRegisterMode => _isRegisterMode;
  String? get error => _error;

  void refreshStrings(AppStrings strings) {
    _strings = strings;
    notifyListeners();
  }

  /// Restores session from device storage (no database).
  Future<void> initialize() async {
    _user = await _authRepository.getCurrentUser();
    _initialized = true;
    notifyListeners();
  }

  /// Seeds demo account and prepares the login database.
  Future<void> prepareLoginScreen() => _authRepository.initialize();

  void setRegisterMode(bool value) {
    _isRegisterMode = value;
    _error = null;
    notifyListeners();
  }

  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    return _authenticate(() => _authRepository.login(
          phone: phone,
          password: password,
        ));
  }

  Future<bool> register({
    required String phone,
    required String password,
    required String displayName,
  }) async {
    return _authenticate(() => _authRepository.register(
          phone: phone,
          password: password,
          displayName: displayName,
        ));
  }

  Future<bool> _authenticate(Future<AuthUser> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await action();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = _strings.t('error_generic');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    notifyListeners();
  }
}
