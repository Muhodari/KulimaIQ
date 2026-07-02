/// Follow-up advice tied to a specific diseased scan on a farm.
class FarmCropSuggestion {
  const FarmCropSuggestion({
    required this.cropId,
    required this.diseaseLabel,
    required this.title,
    required this.summary,
    required this.actions,
    required this.detectedAt,
    required this.confidence,
    this.priority = 'week',
  });

  final String cropId;
  final String diseaseLabel;
  final String title;
  final String summary;
  final List<String> actions;
  final DateTime detectedAt;
  final double confidence;

  /// `now` = act today, `week` = this week, `watch` = monitor only
  final String priority;
}

/// Scan-derived suggestions for one farm (empty unless latest scan is diseased).
class FarmAdvisoryBundle {
  const FarmAdvisoryBundle({required this.suggestions});

  final List<FarmCropSuggestion> suggestions;
}
