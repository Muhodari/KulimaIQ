import '../../domain/models/auth_user.dart';
import '../services/auth_service.dart';

class AuthRepository {
  AuthRepository({required AuthService authService}) : _authService = authService;

  final AuthService _authService;

  Future<void> initialize() => _authService.ensureDemoAccount();

  Future<AuthUser> login({
    required String phone,
    required String password,
  }) =>
      _authService.login(phone: phone, password: password);

  Future<AuthUser> register({
    required String phone,
    required String password,
    required String displayName,
  }) =>
      _authService.register(
        phone: phone,
        password: password,
        displayName: displayName,
      );

  Future<AuthUser?> getCurrentUser() => _authService.getCurrentUser();

  Future<void> logout() => _authService.logout();
}
