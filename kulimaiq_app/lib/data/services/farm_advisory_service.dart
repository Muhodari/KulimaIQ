import '../../domain/models/diagnosis_result.dart';
import '../../domain/models/farm_advisory.dart';
import '../../l10n/app_strings.dart';

/// Builds farm follow-up advice from scan history only.
///
/// Advice appears **only** when the most recent scan on the farm detected a
/// disease. A new scan (healthy or diseased) replaces that state — so after a
/// follow-up rescan the section is hidden until another disease is found.
class FarmAdvisoryService {
  FarmAdvisoryService();

  Future<FarmAdvisoryBundle> buildAdvisories(
    List<DiagnosisResult> scans,
    AppStrings strings,
  ) async {
    if (scans.isEmpty) {
      return const FarmAdvisoryBundle(suggestions: []);
    }

    // History is newest-first; only the latest scan drives follow-up advice.
    final latest = scans.first;
    if (latest.isHealthy) {
      return const FarmAdvisoryBundle(suggestions: []);
    }

    final summary = latest.recommendation?.trim() ?? '';
    final actions = latest.actions;
    if (summary.isEmpty && actions.isEmpty) {
      return const FarmAdvisoryBundle(suggestions: []);
    }

    return FarmAdvisoryBundle(
      suggestions: [
        FarmCropSuggestion(
          cropId: latest.crop.id,
          diseaseLabel: latest.rawDiseaseLabel,
          title: strings.diseaseLabel(latest.rawDiseaseLabel),
          summary: summary.isNotEmpty
              ? summary
              : strings.t('farm_advice_rescan_prompt'),
          actions: actions,
          priority: _priorityFromSeverity(latest.severity),
          detectedAt: latest.createdAt,
          confidence: latest.confidence,
        ),
      ],
    );
  }

  String _priorityFromSeverity(String? severity) {
    final s = severity?.toLowerCase() ?? '';
    if (s.contains('high') || s.contains('critical') || s.contains('severe')) {
      return 'now';
    }
    if (s.contains('low') || s.contains('mild')) return 'watch';
    return 'week';
  }
}
