import 'package:flutter/material.dart';

/// A weather-derived advisory card shown in the Climate tab.
///
/// All text is plain (not l10n keys) so it can be built directly from
/// real Open-Meteo data without going through a translation map.
class ClimateAdvisory {
  const ClimateAdvisory({
    required this.id,
    required this.title,
    required this.body,
    required this.severity,
    required this.validFrom,
    required this.validTo,
    required this.location,
    required this.icon,
  });

  final String id;
  final String title;
  final String body;
  final AdvisorySeverity severity;
  final DateTime validFrom;
  final DateTime validTo;

  /// Human-readable location label (e.g. farm name or "My Farm, Rwanda").
  final String location;
  final IconData icon;
}

enum AdvisorySeverity { low, medium, high }
