import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_logger.dart';
import 'backend_connection_result.dart';

// ── Response models ────────────────────────────────────────────────────────────

class BackendAnalysisResult {
  const BackendAnalysisResult({
    required this.disease,
    required this.confidence,
    required this.recommendation,
    required this.allProbabilities,
    this.severity,
    this.actions = const [],
    this.diagnosisId,
  });

  final String disease;
  final double confidence;
  final String recommendation;
  final Map<String, double> allProbabilities;
  final String? severity;
  final List<String> actions;
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
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
            DateTime.now(),
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

  /// Production API (Render). Used as default for all platforms.
  static const productionUrl = 'https://kulimaiq.onrender.com';

  static String get _defaultUrl => productionUrl;

  static bool _isLegacyLocalUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('localhost') ||
        lower.contains('127.0.0.1') ||
        lower.contains('10.0.2.2') ||
        lower.contains(':8000') ||
        lower.contains(':8001');
  }

  /// Point the app at the hosted API (migrates old localhost URLs).
  Future<void> ensureProductionUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKeyUrl);
    if (saved == null ||
        saved.trim().isEmpty ||
        _isLegacyLocalUrl(saved)) {
      await setBaseUrl(productionUrl);
      ApiLogger.info('Backend URL set to $productionUrl');
    }
  }

  String? _cachedUrl;
  String? _cachedToken;

  // ── Config ─────────────────────────────────────────────────────────────────

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    var url = _cachedUrl ?? prefs.getString(_prefKeyUrl) ?? _defaultUrl;
    if (_isLegacyLocalUrl(url)) {
      url = productionUrl;
      await prefs.setString(_prefKeyUrl, url);
    }
    final normalized = _normalizeUrlForPlatform(url);
    if (normalized != url) {
      url = normalized;
      await prefs.setString(_prefKeyUrl, url);
    }
    _cachedUrl = url;
    return url;
  }

  String _normalizeUrlForPlatform(String url) {
    if (!kIsWeb && !Platform.isAndroid && url.contains('10.0.2.2')) {
      return url.replaceFirst('10.0.2.2', 'localhost');
    }
    return url;
  }

  Future<void> setBaseUrl(String url) async {
    final normalized = _normalizeUrlForPlatform(
      url.trimRight().replaceAll(RegExp(r'/$'), ''),
    );
    _cachedUrl = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyUrl, normalized);
    ApiLogger.info('Backend URL set to $normalized');
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

  void _logFailure(
    String method,
    String url, {
    Object? error,
    int? statusCode,
    String? body,
  }) {
    ApiLogger.failure(
      method,
      url,
      error: error,
      statusCode: statusCode,
      body: body,
    );
  }

  String? _errorBody(http.Response res) {
    final body = res.body.trim();
    return body.isEmpty ? null : body;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  Future<BackendAuthResult?> login(String phone, String password) async {
    final base = await getBaseUrl();
    final url = '$base/auth/login';
    try {
      final res = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone, 'password': password}),
          )
          .timeout(const Duration(seconds: 90));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final result = BackendAuthResult(
          accessToken: data['access_token'] as String,
          userId: (data['user'] as Map)['id'] as String,
          displayName: (data['user'] as Map)['display_name'] as String,
          phone: (data['user'] as Map)['phone'] as String,
        );
        await _saveToken(result.accessToken);
        ApiLogger.success('POST', url, statusCode: res.statusCode);
        return result;
      }
      _logFailure('POST', url,
          statusCode: res.statusCode, body: _errorBody(res));
    } on SocketException catch (e) {
      _logFailure('POST', url, error: 'Network unreachable: $e');
    } on http.ClientException catch (e) {
      _logFailure('POST', url, error: 'Connection failed: $e');
    } catch (e) {
      _logFailure('POST', url, error: e);
    }
    return null;
  }

  Future<BackendAuthResult?> register(
      String phone, String password, String displayName) async {
    final base = await getBaseUrl();
    final url = '$base/auth/register';
    try {
      final res = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': phone,
              'password': password,
              'display_name': displayName,
            }),
          )
          .timeout(const Duration(seconds: 90));
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final result = BackendAuthResult(
          accessToken: data['access_token'] as String,
          userId: (data['user'] as Map)['id'] as String,
          displayName: (data['user'] as Map)['display_name'] as String,
          phone: (data['user'] as Map)['phone'] as String,
        );
        await _saveToken(result.accessToken);
        ApiLogger.success('POST', url, statusCode: res.statusCode);
        return result;
      }
      _logFailure('POST', url,
          statusCode: res.statusCode, body: _errorBody(res));
    } on SocketException catch (e) {
      _logFailure('POST', url, error: 'Network unreachable: $e');
    } on http.ClientException catch (e) {
      _logFailure('POST', url, error: 'Connection failed: $e');
    } catch (e) {
      _logFailure('POST', url, error: e);
    }
    return null;
  }

  // ── Farms ──────────────────────────────────────────────────────────────────

  Future<List<BackendFarm>?> getFarms() async {
    final base = await getBaseUrl();
    final url = '$base/farms/';
    try {
      final headers = await _authHeaders();
      if (!headers.containsKey('Authorization')) {
        _logFailure('GET', url, error: 'No auth token — log in via backend first');
        return null;
      }
      final res = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        final farms = <BackendFarm>[];
        for (final item in list) {
          try {
            farms.add(BackendFarm.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            _logFailure('GET', url, error: 'Skipping malformed farm: $e');
          }
        }
        ApiLogger.success('GET', url, statusCode: res.statusCode);
        return farms;
      }
      _logFailure('GET', url,
          statusCode: res.statusCode, body: _errorBody(res));
    } on SocketException catch (e) {
      _logFailure('GET', url, error: 'Network unreachable: $e');
    } on http.ClientException catch (e) {
      _logFailure('GET', url, error: 'Connection failed: $e');
    } catch (e) {
      _logFailure('GET', url, error: e);
    }
    return null;
  }

  Future<BackendFarm?> createFarm(BackendFarm farm) async {
    final base = await getBaseUrl();
    final url = '$base/farms/';
    try {
      final headers = await _authHeaders();
      if (!headers.containsKey('Authorization')) {
        _logFailure('POST', url, error: 'No auth token — saving farm locally only');
        return null;
      }
      final res = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(farm.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 201) {
        ApiLogger.success('POST', url, statusCode: res.statusCode);
        return BackendFarm.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      }
      _logFailure('POST', url,
          statusCode: res.statusCode, body: _errorBody(res));
    } on SocketException catch (e) {
      _logFailure('POST', url, error: 'Network unreachable: $e');
    } on http.ClientException catch (e) {
      _logFailure('POST', url, error: 'Connection failed: $e');
    } catch (e) {
      _logFailure('POST', url, error: e);
    }
    return null;
  }

  Future<bool> updateFarm(String farmId, BackendFarm farm) async {
    final base = await getBaseUrl();
    final url = '$base/farms/$farmId';
    try {
      final headers = await _authHeaders();
      final res = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(farm.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        ApiLogger.success('PUT', url, statusCode: res.statusCode);
        return true;
      }
      _logFailure('PUT', url,
          statusCode: res.statusCode, body: _errorBody(res));
    } on SocketException catch (e) {
      _logFailure('PUT', url, error: 'Network unreachable: $e');
    } catch (e) {
      _logFailure('PUT', url, error: e);
    }
    return false;
  }

  Future<bool> deleteFarm(String farmId) async {
    final base = await getBaseUrl();
    final url = '$base/farms/$farmId';
    try {
      final headers = await _authHeaders();
      final res = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 204 ||
          res.statusCode == 200 ||
          res.statusCode == 404) {
        ApiLogger.success('DELETE', url, statusCode: res.statusCode);
        return true;
      }
      _logFailure('DELETE', url,
          statusCode: res.statusCode, body: _errorBody(res));
    } on SocketException catch (e) {
      _logFailure('DELETE', url, error: 'Network unreachable: $e');
    } catch (e) {
      _logFailure('DELETE', url, error: e);
    }
    return false;
  }

  // ── Diagnoses ──────────────────────────────────────────────────────────────

  Future<List<BackendDiagnosis>?> getDiagnoses({String? farmId}) async {
    final base = await getBaseUrl();
    final url = '$base/diagnoses/';
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse(url).replace(
        queryParameters: farmId != null ? {'farm_id': farmId} : null,
      );
      final res = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        ApiLogger.success('GET', uri.toString(), statusCode: res.statusCode);
        return list
            .map((e) => BackendDiagnosis.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _logFailure('GET', uri.toString(),
          statusCode: res.statusCode, body: _errorBody(res));
    } on SocketException catch (e) {
      _logFailure('GET', url, error: 'Network unreachable: $e');
    } catch (e) {
      _logFailure('GET', url, error: e);
    }
    return null;
  }

  // ── ML Analysis ────────────────────────────────────────────────────────────

  Future<BackendAnalysisResult?> analyzeImage({
    required String imagePath,
    required String crop,
    String? farmId,
  }) async {
    final base = await getBaseUrl();
    final url = '$base/analyze/image';
    try {
      final token = await getToken();
      if (token == null) {
        _logFailure('POST', url, error: 'No auth token');
        return null;
      }

      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['crop'] = crop
        ..files.add(await http.MultipartFile.fromPath('image', imagePath));
      if (farmId != null) request.fields['farm_id'] = farmId;

      final streamed =
          await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final probs =
            (data['all_probabilities'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        );
        ApiLogger.success('POST', url, statusCode: response.statusCode);
        return BackendAnalysisResult(
          disease: data['disease'] as String,
          confidence: (data['confidence'] as num).toDouble(),
          recommendation: data['recommendation'] as String,
          allProbabilities: probs,
          severity: data['severity'] as String?,
          actions: List<String>.from(data['actions'] as List? ?? const []),
          diagnosisId: data['diagnosis_id'] as String?,
        );
      }
      _logFailure('POST', url,
          statusCode: response.statusCode, body: _errorBody(response));
    } on SocketException catch (e) {
      _logFailure('POST', url, error: 'Network unreachable: $e');
    } catch (e) {
      _logFailure('POST', url, error: e);
    }
    return null;
  }

  // ── Health ─────────────────────────────────────────────────────────────────

  /// Probes `/health` and returns a detailed result (also logged to console).
  Future<BackendConnectionResult> checkConnection() async {
    final base = await getBaseUrl();
    final url = '$base/health';
    ApiLogger.info('Checking $url …');
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 90));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final result = BackendConnectionResult.fromHealthJson(
          url: url,
          statusCode: res.statusCode,
          data: data,
        );
        ApiLogger.success('GET', url, statusCode: res.statusCode);
        ApiLogger.info(result.message);
        return result;
      }
      final message = 'Server returned HTTP ${res.statusCode}';
      _logFailure('GET', url, statusCode: res.statusCode, body: _errorBody(res));
      return BackendConnectionResult.unreachable(
        url: url,
        message: message,
        statusCode: res.statusCode,
      );
    } on SocketException catch (e) {
      const hint =
          'Cannot reach server. Check your internet connection. '
          'The hosted API is https://kulimaiq.onrender.com — '
          'first request after idle may take up to a minute.';
      _logFailure('GET', url, error: '$e — $hint');
      return BackendConnectionResult.unreachable(
        url: url,
        message: hint,
      );
    } on http.ClientException catch (e) {
      _logFailure('GET', url, error: e);
      return BackendConnectionResult.unreachable(
        url: url,
        message: 'Connection failed: $e',
      );
    } catch (e) {
      _logFailure('GET', url, error: e);
      return BackendConnectionResult.unreachable(
        url: url,
        message: e.toString(),
      );
    }
  }

  Future<bool> isBackendReady() async {
    final result = await checkConnection();
    return result.ok;
  }
}
