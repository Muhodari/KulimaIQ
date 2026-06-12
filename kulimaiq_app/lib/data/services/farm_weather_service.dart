import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/farm_weather.dart';

/// Fetches current weather for a GPS coordinate using the free Open-Meteo API.
/// No API key required.
class FarmWeatherService {
  FarmWeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Fetches the current weather at [latitude]/[longitude].
  /// Returns null if the request fails (e.g. offline).
  Future<FarmWeather?> fetchWeather(double latitude, double longitude) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'latitude': latitude.toStringAsFixed(6),
        'longitude': longitude.toStringAsFixed(6),
        'current_weather': 'true',
      });
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return FarmWeather.fromJson(json);
      }
    } catch (_) {
      // Network unavailable or timeout — return null silently.
    }
    return null;
  }
}
