import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ── Response models ────────────────────────────────────────────────────────────

class BackendAnalysisResult {
  const BackendAnalysisResult({
    required this.disease,
    required this.confidence,
    required this.recommendation,
    required this.allProbabilities,
    this.diagnosisId,
  });

  final String disease;
  final double confidence;
  final String recommendation;
  final Map<String, double> allProbabilities;
  final String? diagnosisId;
}

class BackendAuthResult {
  const BackendAuthResult({
    required this.accessToken,
    required this.userId,
    required this.displayName,
    required this.phone,
  });

  final String accessToken;
  final String userId;
  final String displayName;
  final String phone;
}

class BackendFarm {
  const BackendFarm({
    required this.id,
    required this.name,
    required this.country,
    required this.region,
    this.latitude,
    this.longitude,
    required this.sizeHa,
    required this.crops,
    required this.healthStatus,
    this.lastScannedAt,
    required this.createdAt,
    this.notes = '',
    this.healthScore,
  });

  final String id;
  final String name;
  final String country;
  final String region;
  final double? latitude;
  final double? longitude;
  final double sizeHa;
  final List<String> crops;
  final String healthStatus;
  final DateTime? lastScannedAt;
  final DateTime createdAt;
  final String notes;
  final double? healthScore;

  factory BackendFarm.fromJson(Map<String, dynamic> j) => BackendFarm(
        id: j['id'] as String,
        name: j['name'] as String,
        country: (j['country'] as String?) ?? '',
        region: (j['region'] as String?) ?? '',
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        sizeHa: (j['size_ha'] as num?)?.toDouble() ?? 0,
        crops: List<String>.from(j['crops'] as List? ?? []),
        healthStatus: (j['health_status'] as String?) ?? 'unknown',
        lastScannedAt: j['last_scanned_at'] != null
            ? DateTime.tryParse(j['last_scanned_at'] as String)
            : null,
        createdAt: DateTime.parse(j['created_at'] as String),
        notes: (j['notes'] as String?) ?? '',
        healthScore: (j['health_score'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'country': country,
        'region': region,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'size_ha': sizeHa,
        'crops': crops,
        'health_status': healthStatus,
        'notes': notes,
      };
}

class BackendDiagnosis {
  const BackendDiagnosis({
    required this.id,
    required this.crop,
    required this.disease,
    required this.confidence,
    required this.recommendation,
    required this.createdAt,
    this.severity,
    this.actions = const [],
    this.farmId,
    this.imagePath = '',
  });

  final String id;
  final String crop;
  final String disease;
  final double confidence;
  final String recommendation;
  final DateTime createdAt;
  final String? severity;
  final List<String> actions;
  final String? farmId;
  final String imagePath;

  factory BackendDiagnosis.fromJson(Map<String, dynamic> j) => BackendDiagnosis(
        id: j['id'] as String,
        crop: (j['crop'] as String?) ?? '',
        disease: (j['disease'] as String?) ?? 'healthy',
        confidence: (j['confidence'] as num).toDouble(),
        recommendation: (j['recommendation'] as String?) ?? '',
        createdAt: DateTime.parse(j['created_at'] as String),
        severity: j['severity'] as String?,
        actions: List<String>.from(j['actions'] as List? ?? []),
        farmId: j['farm_id'] as String?,
        imagePath: '',
      );
}

// ── Service ────────────────────────────────────────────────────────────────────

/// HTTP client for the KulimaIQ FastAPI backend.
///
/// Backend URL and JWT token are persisted in SharedPreferences.
/// All methods return null / empty on failure so callers can fall back offline.
class BackendApiService {
  static const _prefKeyUrl = 'backend_url';
  static const _prefKeyToken = 'backend_token';
  static const _defaultUrl = 'http://10.0.2.2:8001'; // Android emulator
  // iOS simulator → 'http://localhost:8001'
  // Real device   → 'http://<machine-ip>:8001'

  String? _cachedUrl;
  String? _cachedToken;

  // ── Config ─────────────────────────────────────────────────────────────────

  Future<String> getBaseUrl() async {
    if (_cachedUrl != null) return _cachedUrl!;
    final prefs = await SharedPreferences.getInstance();
    _cachedUrl = prefs.getString(_prefKeyUrl) ?? _defaultUrl;
    return _cachedUrl!;
  }

  Future<void> setBaseUrl(String url) async {
    _cachedUrl = url.trimRight().replaceAll(RegExp(r'/$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyUrl, _cachedUrl!);
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_prefKeyToken);
    return _cachedToken;
  }

  Future<void> _saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyToken, token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyToken);
  }

  bool get isConfigured => _cachedToken != null;

  // ── Request helpers ────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  Future<BackendAuthResult?> login(String phone, String password) async {
    try {
      final base = await getBaseUrl();
      final res = await http
          .post(
            Uri.parse('$base/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final result = BackendAuthResult(
          accessToken: data['access_token'] as String,
          userId: (data['user'] as Map)['id'] as String,
          displayName: (data['user'] as Map)['display_name'] as String,
          phone: (data['user'] as Map)['phone'] as String,
        );
        await _saveToken(result.accessToken);
        return result;
      }
    } catch (_) {}
    return null;
  }

  Future<BackendAuthResult?> register(
      String phone, String password, String displayName) async {
    try {
      final base = await getBaseUrl();
      final res = await http
          .post(
            Uri.parse('$base/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': phone,
              'password': password,
              'display_name': displayName,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final result = BackendAuthResult(
          accessToken: data['access_token'] as String,
          userId: (data['user'] as Map)['id'] as String,
          displayName: (data['user'] as Map)['display_name'] as String,
          phone: (data['user'] as Map)['phone'] as String,
        );
        await _saveToken(result.accessToken);
        return result;
      }
    } catch (_) {}
    return null;
  }

  // ── Farms ──────────────────────────────────────────────────────────────────

  Future<List<BackendFarm>?> getFarms() async {
    try {
      final base = await getBaseUrl();
      final headers = await _authHeaders();
      final res = await http
          .get(Uri.parse('$base/farms/'), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list
            .map((e) => BackendFarm.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } on SocketException {
      // offline
    } catch (_) {}
    return null;
  }

  Future<BackendFarm?> createFarm(BackendFarm farm) async {
    try {
      final base = await getBaseUrl();
      final headers = await _authHeaders();
      final res = await http
          .post(
            Uri.parse('$base/farms/'),
            headers: headers,
            body: jsonEncode(farm.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 201) {
        return BackendFarm.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      }
    } on SocketException {
      // offline
    } catch (_) {}
    return null;
  }

  Future<bool> updateFarm(String farmId, BackendFarm farm) async {
    try {
      final base = await getBaseUrl();
      final headers = await _authHeaders();
      final res = await http
          .put(
            Uri.parse('$base/farms/$farmId'),
            headers: headers,
            body: jsonEncode(farm.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } on SocketException {
      // offline
    } catch (_) {}
    return false;
  }

  Future<bool> deleteFarm(String farmId) async {
    try {
      final base = await getBaseUrl();
      final headers = await _authHeaders();
      final res = await http
          .delete(Uri.parse('$base/farms/$farmId'), headers: headers)
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 204 || res.statusCode == 200;
    } on SocketException {
      // offline
    } catch (_) {}
    return false;
  }

  // ── Diagnoses ──────────────────────────────────────────────────────────────

  Future<List<BackendDiagnosis>?> getDiagnoses({String? farmId}) async {
    try {
      final base = await getBaseUrl();
      final headers = await _authHeaders();
      final uri = Uri.parse('$base/diagnoses/').replace(
        queryParameters: farmId != null ? {'farm_id': farmId} : null,
      );
      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list
            .map((e) => BackendDiagnosis.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } on SocketException {
      // offline
    } catch (_) {}
    return null;
  }

  // ── ML Analysis ────────────────────────────────────────────────────────────

  Future<BackendAnalysisResult?> analyzeImage({
    required String imagePath,
    required String crop,
    String? farmId,
  }) async {
    try {
      final base = await getBaseUrl();
      final token = await getToken();
      if (token == null) return null;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$base/analyze/image'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['crop'] = crop
        ..files.add(await http.MultipartFile.fromPath('image', imagePath));
      if (farmId != null) request.fields['farm_id'] = farmId;

      final streamed =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final probs =
            (data['all_probabilities'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        );
        return BackendAnalysisResult(
          disease: data['disease'] as String,
          confidence: (data['confidence'] as num).toDouble(),
          recommendation: data['recommendation'] as String,
          allProbabilities: probs,
          diagnosisId: data['diagnosis_id'] as String?,
        );
      }
    } on SocketException {
      // offline
    } catch (_) {}
    return null;
  }

  // ── Health ─────────────────────────────────────────────────────────────────

  Future<bool> isBackendReady() async {
    try {
      final base = await getBaseUrl();
      final res = await http
          .get(Uri.parse('$base/health'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['ml_model_ready'] == true;
      }
    } catch (_) {}
    return false;
  }
}
