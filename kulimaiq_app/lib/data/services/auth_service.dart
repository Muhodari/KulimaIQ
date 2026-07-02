import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/models/auth_user.dart';
import 'api_logger.dart';
import 'backend_api_service.dart';
import 'database_service.dart';
import 'preferences_service.dart';

class AuthService {
  AuthService({
    required DatabaseService databaseService,
    required PreferencesService preferencesService,
    required BackendApiService backendApiService,
  })  : _databaseService = databaseService,
        _preferencesService = preferencesService,
        _backendApiService = backendApiService;

  final DatabaseService _databaseService;
  final PreferencesService _preferencesService;
  final BackendApiService _backendApiService;

  static const demoPhone = '+250788000000';
  static const demoPassword = 'farmer123';
  static const demoName = 'Demo Farmer';

  Future<void> ensureDemoAccount() async {
    final db = await _databaseService.database;
    final existing = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [demoPhone],
      limit: 1,
    );
    if (existing.isEmpty) {
      await _createLocalUser(
        db: db,
        phone: demoPhone,
        password: demoPassword,
        displayName: demoName,
      );
    }

    // Mirror demo account on the backend so login returns a JWT for farm sync.
    final backendUser =
        await _backendApiService.login(demoPhone, demoPassword);
    if (backendUser == null) {
      await _backendApiService.register(demoPhone, demoPassword, demoName);
      await _backendApiService.login(demoPhone, demoPassword);
    }
  }

  /// Login: tries backend first, falls back to local SQLite.
  Future<AuthUser> login({
    required String phone,
    required String password,
  }) async {
    // 1. Try backend
    final backendResult =
        await _backendApiService.login(phone.trim(), password);
    if (backendResult != null) {
      final user = AuthUser(
        id: backendResult.userId,
        phone: backendResult.phone,
        displayName: backendResult.displayName,
      );
      await _preferencesService.saveSession(
        userId: user.id,
        phone: user.phone,
        displayName: user.displayName,
      );
      // Mirror into local DB so offline works later
      await _upsertLocalUser(user: user, password: password);
      return user;
    }

    ApiLogger.info(
      'Backend login unavailable — using local account for ${phone.trim()}',
    );

    // Demo credentials: ensure backend account exists, then retry for a JWT.
    if (phone.trim() == demoPhone && password == demoPassword) {
      await _backendApiService.register(demoPhone, demoPassword, demoName);
      final retry = await _backendApiService.login(demoPhone, demoPassword);
      if (retry != null) {
        final user = AuthUser(
          id: retry.userId,
          phone: retry.phone,
          displayName: retry.displayName,
        );
        await _preferencesService.saveSession(
          userId: user.id,
          phone: user.phone,
          displayName: user.displayName,
        );
        await _upsertLocalUser(user: user, password: password);
        ApiLogger.info('Backend demo account linked after retry');
        return user;
      }
    }

    return _localLogin(phone: phone, password: password);
  }

  /// Register: tries backend first (creates account in MongoDB), mirrors locally.
  Future<AuthUser> register({
    required String phone,
    required String password,
    required String displayName,
  }) async {
    final normalizedPhone = phone.trim();
    if (normalizedPhone.length < 9) {
      throw AuthException('Enter a valid phone number.');
    }
    if (password.length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }
    if (displayName.trim().isEmpty) {
      throw AuthException('Enter your full name.');
    }

    // 1. Try backend registration
    final backendResult = await _backendApiService.register(
        normalizedPhone, password, displayName.trim());
    if (backendResult != null) {
      final user = AuthUser(
        id: backendResult.userId,
        phone: backendResult.phone,
        displayName: backendResult.displayName,
      );
      await _preferencesService.saveSession(
        userId: user.id,
        phone: user.phone,
        displayName: user.displayName,
      );
      await _upsertLocalUser(user: user, password: password);
      return user;
    }

    ApiLogger.info('Backend register unavailable — creating local account only');
    return _localRegister(
        phone: normalizedPhone, password: password, displayName: displayName);
  }

  Future<AuthUser?> getCurrentUser() async {
    final session = await _preferencesService.getSession();
    if (session == null) return null;
    return AuthUser(
      id: session.userId,
      phone: session.phone,
      displayName: session.displayName,
    );
  }

  /// If the user is signed in locally but has no backend JWT, log in again.
  Future<void> refreshBackendSession() async {
    final user = await getCurrentUser();
    if (user == null) return;
    if (await _backendApiService.getToken() != null) return;

    if (user.phone == demoPhone) {
      ApiLogger.info('Restoring backend JWT for demo account');
      var result = await _backendApiService.login(demoPhone, demoPassword);
      if (result == null) {
        await _backendApiService.register(demoPhone, demoPassword, demoName);
        result = await _backendApiService.login(demoPhone, demoPassword);
      }
      if (result != null) {
        ApiLogger.info('Backend session restored');
      }
    }
  }

  Future<void> logout() async {
    await _backendApiService.clearToken();
    await _preferencesService.clearSession();
  }

  // ── Local helpers ──────────────────────────────────────────────────────────

  Future<AuthUser> _localLogin(
      {required String phone, required String password}) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [phone.trim()],
      limit: 1,
    );
    if (rows.isEmpty) throw AuthException('Invalid phone number or password.');
    final row = rows.first;
    final hash = row['password_hash']! as String;
    if (hash != _hashPassword(password)) {
      throw AuthException('Invalid phone number or password.');
    }
    final user = AuthUser(
      id: row['id']! as String,
      phone: row['phone']! as String,
      displayName: row['display_name']! as String,
    );
    await _preferencesService.saveSession(
      userId: user.id,
      phone: user.phone,
      displayName: user.displayName,
    );
    return user;
  }

  Future<AuthUser> _localRegister({
    required String phone,
    required String password,
    required String displayName,
  }) async {
    final db = await _databaseService.database;
    final existing = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [phone],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw AuthException('This phone number is already registered.');
    }
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await db.insert('users', {
      'id': id,
      'phone': phone,
      'password_hash': _hashPassword(password),
      'display_name': displayName.trim(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    final user = AuthUser(
      id: id,
      phone: phone,
      displayName: displayName.trim(),
    );
    await _preferencesService.saveSession(
      userId: user.id,
      phone: user.phone,
      displayName: user.displayName,
    );
    return user;
  }

  Future<void> _upsertLocalUser(
      {required AuthUser user, required String password}) async {
    final db = await _databaseService.database;
    final existing = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [user.id],
      limit: 1,
    );
    final row = {
      'id': user.id,
      'phone': user.phone,
      'password_hash': _hashPassword(password),
      'display_name': user.displayName,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
    if (existing.isEmpty) {
      await db.insert('users', row);
    } else {
      await db.update('users', row, where: 'id = ?', whereArgs: [user.id]);
    }
  }

  Future<void> _createLocalUser({
    required Database db,
    required String phone,
    required String password,
    required String displayName,
  }) async {
    await db.insert('users', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'phone': phone,
      'password_hash': _hashPassword(password),
      'display_name': displayName,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  String _hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
