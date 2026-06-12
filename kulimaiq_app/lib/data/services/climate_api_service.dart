import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/climate_advisory.dart';

/// Fetches a 7-day weather forecast from Open-Meteo (free, no API key) and
/// converts the data into actionable [ClimateAdvisory] cards.
class ClimateApiService {
  ClimateApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Returns a list of advisories for the given GPS coordinate and [location]
  /// label (e.g. "My Farm, Rwanda"). Returns an empty list on any error.
  Future<List<ClimateAdvisory>> fetchAdvisories({
    required double latitude,
    required double longitude,
    required String location,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'latitude': latitude.toStringAsFixed(6),
        'longitude': longitude.toStringAsFixed(6),
        'daily': [
          'weathercode',
          'temperature_2m_max',
          'temperature_2m_min',
          'precipitation_sum',
          'windspeed_10m_max',
          'precipitation_probability_max',
        ].join(','),
        'forecast_days': '7',
        'timezone': 'auto',
      });

      final res = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return _buildAdvisories(json, location);
    } catch (_) {
      return [];
    }
  }

  // ── Advisory generation ────────────────────────────────────────────────────

  List<ClimateAdvisory> _buildAdvisories(
      Map<String, dynamic> json, String location) {
    final daily = json['daily'] as Map<String, dynamic>?;
    if (daily == null) return [];

    final dates = List<String>.from(daily['time'] as List? ?? []);
    // weathercode is not currently used directly — conditions are derived
    // from precipitation_sum, temperature, and windspeed instead.
    final maxTemps = _doubles(daily['temperature_2m_max']);
    final minTemps = _doubles(daily['temperature_2m_min']);
    final precip = _doubles(daily['precipitation_sum']);
    final wind = _doubles(daily['windspeed_10m_max']);
    final precipProb =
        _doubles(daily['precipitation_probability_max']);

    final advisories = <ClimateAdvisory>[];
    final now = DateTime.now();

    // ── Heavy rain / flooding risk ───────────────────────────────────────────
    final rainDays = _daysWithCondition(
      count: dates.length,
      precip: precip,
      threshold: 15,
    );
    if (rainDays.isNotEmpty) {
      final firstDay = _parseDate(dates[rainDays.first]);
      advisories.add(ClimateAdvisory(
        id: 'rain-heavy-$location',
        title: 'Heavy rain expected',
        body: 'Significant rainfall (≥ 15 mm) is forecast on '
            '${_formatDays(rainDays, dates)}. '
            'Avoid spraying pesticides and ensure field drainage is clear. '
            'Delay weeding until soil conditions improve.',
        severity: AdvisorySeverity.high,
        validFrom: now,
        validTo: firstDay.add(const Duration(days: 2)),
        location: location,
        icon: Icons.thunderstorm_rounded,
      ));
    } else {
      // Check for moderate rain
      final lightRainDays = _daysWithCondition(
        count: dates.length,
        precip: precip,
        threshold: 3,
      );
      if (lightRainDays.isNotEmpty) {
        final firstDay = _parseDate(dates[lightRainDays.first]);
        advisories.add(ClimateAdvisory(
          id: 'rain-light-$location',
          title: 'Rainfall expected',
          body: 'Light to moderate rain (3–15 mm) forecast on '
              '${_formatDays(lightRainDays, dates)}. '
              'Good opportunity to reduce irrigation. '
              'Check field drainage and ensure no waterlogging in low areas.',
          severity: AdvisorySeverity.medium,
          validFrom: now,
          validTo: firstDay.add(const Duration(days: 1)),
          location: location,
          icon: Icons.umbrella_rounded,
        ));
      }
    }

    // ── Heat stress ──────────────────────────────────────────────────────────
    final hotDays = <int>[];
    for (var i = 0; i < maxTemps.length; i++) {
      if (maxTemps[i] > 35) hotDays.add(i);
    }
    if (hotDays.isNotEmpty) {
      advisories.add(ClimateAdvisory(
        id: 'heat-$location',
        title: 'Heat stress risk',
        body: 'Temperatures above 35 °C expected on '
            '${_formatDays(hotDays, dates)}. '
            'Irrigate early morning or evening to reduce evaporation. '
            'Mulch around crops to retain soil moisture and protect roots.',
        severity: AdvisorySeverity.high,
        validFrom: now,
        validTo: _parseDate(dates[hotDays.last]).add(const Duration(days: 1)),
        location: location,
        icon: Icons.wb_sunny_rounded,
      ));
    }

    // ── Cold / frost risk ────────────────────────────────────────────────────
    final coldDays = <int>[];
    for (var i = 0; i < minTemps.length; i++) {
      if (minTemps[i] < 10) coldDays.add(i);
    }
    if (coldDays.isNotEmpty) {
      advisories.add(ClimateAdvisory(
        id: 'cold-$location',
        title: 'Cold spell warning',
        body: 'Night temperatures below 10 °C forecast on '
            '${_formatDays(coldDays, dates)}. '
            'Cover sensitive seedlings overnight. '
            'Delay transplanting until temperatures stabilise above 12 °C.',
        severity: AdvisorySeverity.medium,
        validFrom: now,
        validTo: _parseDate(dates[coldDays.last]).add(const Duration(days: 1)),
        location: location,
        icon: Icons.ac_unit_rounded,
      ));
    }

    // ── High winds ───────────────────────────────────────────────────────────
    final windDays = <int>[];
    for (var i = 0; i < wind.length; i++) {
      if (wind[i] > 50) windDays.add(i);
    }
    if (windDays.isNotEmpty) {
      advisories.add(ClimateAdvisory(
        id: 'wind-$location',
        title: 'High wind advisory',
        body: 'Strong winds (> 50 km/h) expected on '
            '${_formatDays(windDays, dates)}. '
            'Stake tall crops such as maize and banana. '
            'Avoid spraying agrochemicals on windy days.',
        severity: AdvisorySeverity.medium,
        validFrom: now,
        validTo: _parseDate(dates[windDays.last]).add(const Duration(days: 1)),
        location: location,
        icon: Icons.air_rounded,
      ));
    }

    // ── Dry spell ────────────────────────────────────────────────────────────
    final dryStreak = _longestDryStreak(precip);
    if (dryStreak >= 4) {
      advisories.add(ClimateAdvisory(
        id: 'dry-$location',
        title: 'Dry spell — $dryStreak consecutive dry days',
        body: 'No significant rain expected for $dryStreak days. '
            'Increase irrigation frequency for water-demanding crops. '
            'Apply mulch to conserve soil moisture and reduce water stress.',
        severity: dryStreak >= 6 ? AdvisorySeverity.high : AdvisorySeverity.medium,
        validFrom: now,
        validTo: now.add(Duration(days: dryStreak)),
        location: location,
        icon: Icons.grain_rounded,
      ));
    }

    // ── Favourable planting window ───────────────────────────────────────────
    // Good if: some rain expected, max temp < 35, no heavy rain
    final hasMildRain = precip.any((p) => p >= 2 && p <= 12);
    final noExtreme = maxTemps.every((t) => t < 35) && rainDays.isEmpty;
    if (hasMildRain && noExtreme) {
      final avgHigh = maxTemps.reduce((a, b) => a + b) / maxTemps.length;
      advisories.add(ClimateAdvisory(
        id: 'planting-$location',
        title: 'Favourable planting conditions',
        body: 'The next 7 days show mild rainfall and moderate temperatures '
            '(avg. high ${avgHigh.toStringAsFixed(1)} °C) — ideal for sowing '
            'or transplanting. Prepare seed beds and ensure adequate spacing.',
        severity: AdvisorySeverity.low,
        validFrom: now,
        validTo: now.add(const Duration(days: 7)),
        location: location,
        icon: Icons.eco_rounded,
      ));
    }

    // ── High rain probability ─────────────────────────────────────────────────
    final highProbDays = <int>[];
    for (var i = 0; i < precipProb.length; i++) {
      if (precipProb[i] >= 75) highProbDays.add(i);
    }
    if (highProbDays.length >= 3 && rainDays.isEmpty) {
      advisories.add(ClimateAdvisory(
        id: 'rainprob-$location',
        title: 'High probability of rain (${highProbDays.length} days)',
        body: 'Rain is likely (≥ 75%) on '
            '${_formatDays(highProbDays, dates)}. '
            'Schedule field operations for drier days. '
            'Consider fungal disease prevention sprays before rain.',
        severity: AdvisorySeverity.low,
        validFrom: now,
        validTo: _parseDate(dates[highProbDays.last])
            .add(const Duration(days: 1)),
        location: location,
        icon: Icons.cloud_rounded,
      ));
    }

    return advisories;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<double> _doubles(dynamic raw) {
    if (raw == null) return [];
    return List<double>.from(
        (raw as List).map((e) => (e as num?)?.toDouble() ?? 0.0));
  }

  List<int> _daysWithCondition({
    required int count,
    required List<double> precip,
    required double threshold,
  }) {
    final result = <int>[];
    for (var i = 0; i < count && i < precip.length; i++) {
      if (precip[i] >= threshold) result.add(i);
    }
    return result;
  }

  int _longestDryStreak(List<double> precip) {
    int best = 0, current = 0;
    for (final p in precip) {
      if (p < 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 0;
      }
    }
    return best;
  }

  DateTime _parseDate(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {
      return DateTime.now();
    }
  }

  String _formatDays(List<int> indices, List<String> dates) {
    if (indices.isEmpty) return '';
    final labels = indices.take(3).map((i) {
      try {
        final d = DateTime.parse(dates[i]);
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${months[d.month - 1]} ${d.day}';
      } catch (_) {
        return dates[i];
      }
    }).join(', ');
    return indices.length > 3 ? '$labels…' : labels;
  }
}
