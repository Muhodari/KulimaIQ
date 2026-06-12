import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  const UserSession({
    required this.userId,
    required this.phone,
    required this.displayName,
  });

  final String userId;
  final String phone;
  final String displayName;
}

class PreferencesService {
  static const _localeKey = 'locale';
  static const _onboardingKey = 'onboarding_complete';
  static const _sessionUserIdKey = 'session_user_id';
  static const _sessionPhoneKey = 'session_phone';
  static const _sessionNameKey = 'session_display_name';

  Future<String> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey) ?? 'en';
  }

  Future<void> setLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, code);
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingComplete(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, value);
  }

  Future<void> saveSession({
    required String userId,
    required String phone,
    required String displayName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionUserIdKey, userId);
    await prefs.setString(_sessionPhoneKey, phone);
    await prefs.setString(_sessionNameKey, displayName);
  }

  Future<UserSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_sessionUserIdKey);
    final phone = prefs.getString(_sessionPhoneKey);
    final name = prefs.getString(_sessionNameKey);
    if (userId == null || phone == null || name == null) return null;
    return UserSession(userId: userId, phone: phone, displayName: name);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionUserIdKey);
    await prefs.remove(_sessionPhoneKey);
    await prefs.remove(_sessionNameKey);
  }
}
