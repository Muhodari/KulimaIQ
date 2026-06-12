import 'package:flutter/material.dart';

/// Snapshot of current weather conditions for a farm's GPS location.
class FarmWeather {
  const FarmWeather({
    required this.temperatureC,
    required this.windspeedKmh,
    required this.weatherCode,
    required this.isDay,
    required this.fetchedAt,
  });

  final double temperatureC;
  final double windspeedKmh;

  /// WMO weather interpretation code (0 = clear sky, etc.)
  final int weatherCode;
  final bool isDay;
  final DateTime fetchedAt;

  String get description => _descriptionFor(weatherCode);
  IconData get icon => _iconFor(weatherCode, isDay);

  static String _descriptionFor(int code) {
    if (code == 0) return 'Clear sky';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 55) return 'Drizzle';
    if (code <= 65) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain showers';
    if (code <= 86) return 'Snow showers';
    return 'Thunderstorm';
  }

  static IconData _iconFor(int code, bool isDay) {
    if (code == 0) return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    if (code <= 3) return Icons.wb_cloudy_outlined;
    if (code <= 48) return Icons.foggy;
    if (code <= 65) return Icons.grain_rounded;
    if (code <= 77) return Icons.ac_unit_rounded;
    if (code <= 82) return Icons.umbrella_rounded;
    if (code <= 86) return Icons.ac_unit_rounded;
    return Icons.thunderstorm_rounded;
  }

  factory FarmWeather.fromJson(Map<String, dynamic> json) {
    final cw = json['current_weather'] as Map<String, dynamic>;
    return FarmWeather(
      temperatureC: (cw['temperature'] as num).toDouble(),
      windspeedKmh: (cw['windspeed'] as num).toDouble(),
      weatherCode: (cw['weathercode'] as num).toInt(),
      isDay: (cw['is_day'] as num) == 1,
      fetchedAt: DateTime.now(),
    );
  }
}
