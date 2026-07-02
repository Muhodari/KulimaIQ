import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/diagnosis_repository.dart';
import '../../../../data/services/farm_advisory_service.dart';
import '../../../../domain/models/crop_type.dart';
import '../../../../domain/models/diagnosis_result.dart';
import '../../../../domain/models/farm.dart';
import '../../../../domain/models/farm_advisory.dart';
import '../../../../l10n/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/confidence_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/kulima_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../shell/app_shell_view_model.dart';
import '../../scan/view_models/scan_view_model.dart';
import '../view_models/farm_detail_view_model.dart';
import '../view_models/farm_view_model.dart';
import 'farm_form_sheet.dart';

class FarmDetailPage extends StatelessWidget {
  const FarmDetailPage({super.key, required this.farm});

  final Farm farm;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => FarmDetailViewModel(
        farm: farm,
        farmViewModel: ctx.read<FarmViewModel>(),
        diagnosisRepository: ctx.read<DiagnosisRepository>(),
        advisoryService: ctx.read<FarmAdvisoryService>(),
        strings: ctx.read<FarmViewModel>().strings,
      ),
      child: const _FarmDetailBody(),
    );
  }
}

class _FarmDetailBody extends StatelessWidget {
  const _FarmDetailBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FarmDetailViewModel>();
    final s = vm.strings;
    final farm = vm.farm;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          farm.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: s.t('farm_edit_title'),
            onPressed: () => _openEdit(context, farm),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _scanFarm(context, farm),
        backgroundColor: AppTheme.primary,
        elevation: 6,
        highlightElevation: 8,
        icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
        label: Text(
          s.t('farm_scan_cta'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : DecoratedBox(
              decoration: const BoxDecoration(
                gradient: AppTheme.pageGradient,
              ),
              child: RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: vm.load,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
                    AppSpacing.screenPadding,
                    100,
                  ),
                  children: [
                    SectionHeader(
                      title: s.t('farm_section_overview'),
                      subtitle: s.t('farm_list_subtitle'),
                    ),
                    _HeroHeader(vm: vm),
                    if (vm.error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ErrorBanner(message: vm.error!),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    if (vm.suggestions.isNotEmpty) ...[
                      SectionHeader(
                        title: s.t('farm_section_actions'),
                        subtitle: s.t('farm_section_actions_sub'),
                      ),
                      ...vm.suggestions.map(
                        (sg) => _SuggestionCard(sg: sg, s: s),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                    SectionHeader(
                      title: s.t('farm_detail_crops'),
                      subtitle: s.t('farm_detail_crops_sub'),
                    ),
                    _CropsSection(farm: farm, strings: s),
                    const SizedBox(height: AppSpacing.xxl),
                    SectionHeader(
                      title: s.t('farm_detail_scans'),
                      subtitle: s.t('farm_detail_scans_sub'),
                    ),
                    if (vm.scans.isEmpty)
                      EmptyState(
                        icon: Icons.document_scanner_outlined,
                        message: s.t('farm_detail_no_scans'),
                        actionLabel: s.t('farm_scan_cta'),
                        onAction: () => _scanFarm(context, farm),
                      )
                    else
                      ...vm.scans.take(8).map(
                            (scan) => _ScanTile(scan: scan, s: s),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  void _scanFarm(BuildContext context, Farm farm) {
    context.read<ScanViewModel>().beginFarmScan(farm);
    context.read<AppShellViewModel>().setTab(1);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openEdit(BuildContext context, Farm farm) {
    final fvm = context.read<FarmViewModel>();
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: fvm,
        child: FarmFormSheet(farm: farm),
      ),
    ).then((deleted) {
      if (!context.mounted) return;
      if (deleted == true) {
        Navigator.of(context).pop();
        return;
      }
      context.read<FarmDetailViewModel>().load();
    });
  }
}

// ── Hero header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.vm});
  final FarmDetailViewModel vm;

  Color _statusColor(FarmHealthStatus status) => switch (status) {
        FarmHealthStatus.healthy => AppTheme.primary,
        FarmHealthStatus.atRisk => AppTheme.warning,
        FarmHealthStatus.diseased => AppTheme.error,
        FarmHealthStatus.unknown => AppTheme.textSecondary,
      };

  String _statusLabel(FarmHealthStatus status, AppStrings s) => switch (status) {
        FarmHealthStatus.healthy => s.t('farm_status_healthy'),
        FarmHealthStatus.atRisk => s.t('farm_status_at_risk'),
        FarmHealthStatus.diseased => s.t('farm_status_diseased'),
        FarmHealthStatus.unknown => s.t('farm_status_unknown'),
      };

  @override
  Widget build(BuildContext context) {
    final farm = vm.farm;
    final s = vm.strings;
    final score = farm.healthScore;
    final statusColor = _statusColor(farm.healthStatus);
    final lastScan = farm.lastScannedAt != null
        ? DateFormat.yMMMd().format(farm.lastScannedAt!)
        : s.t('farm_never_scanned');

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.landscape_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    farm.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (score != null) _ScoreRing(score: score),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30),
              ),
              child: Text(
                _statusLabel(farm.healthStatus, s),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _GlassStat(
                    icon: Icons.straighten_rounded,
                    label: s.t('farm_field_size'),
                    value: '${farm.sizeHa} ha',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _GlassStat(
                    icon: Icons.favorite_rounded,
                    label: s.t('farm_detail_health'),
                    value: score != null
                        ? '${score.toStringAsFixed(0)}%'
                        : s.t('farm_no_data'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _GlassStat(
              icon: Icons.schedule_rounded,
              label: s.t('farm_detail_scans'),
              value: lastScan,
              fullWidth: true,
            ),
            if (farm.notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                farm.notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});
  final double score;

  Color get _color => AppTheme.scoreColor(score);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 6,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation(_color),
          ),
          Center(
            child: Text(
              '${score.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassStat extends StatelessWidget {
  const _GlassStat({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: const TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

// ── Crops ─────────────────────────────────────────────────────────────────────

class _CropsSection extends StatelessWidget {
  const _CropsSection({required this.farm, required this.strings});
  final Farm farm;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    if (farm.crops.isEmpty) {
      return EmptyState(
        icon: Icons.eco_outlined,
        message: strings.t('farm_detail_no_crops'),
      );
    }

    return KulimaCard(
      child: SizedBox(
        height: 88,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: farm.crops.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final crop = farm.crops[index];
            return _CropTile(crop: crop, label: strings.cropLabel(crop.id));
          },
        ),
      ),
    );
  }
}

class _CropTile extends StatelessWidget {
  const _CropTile({required this.crop, required this.label});
  final CropType crop;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: crop.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(crop.icon, color: AppTheme.primary, size: 26),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Suggestions ─────────────────────────────────────────────────────────────

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.sg, required this.s});
  final FarmCropSuggestion sg;
  final AppStrings s;

  CropType? get _crop => CropType.fromId(sg.cropId);

  String _priorityLabel() => switch (sg.priority) {
        'now' => s.t('farm_priority_now'),
        'week' => s.t('farm_priority_week'),
        _ => s.t('farm_priority_watch'),
      };

  Color _priorityColor() => switch (sg.priority) {
        'now' => AppTheme.error,
        'week' => AppTheme.warning,
        _ => AppTheme.primary,
      };

  @override
  Widget build(BuildContext context) {
    final crop = _crop;
    final priorityColor = _priorityColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: KulimaCard(
        accentColor: priorityColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (crop != null)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: crop.color,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(crop.icon, color: AppTheme.primary, size: 22),
                  ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.cropLabel(sg.cropId),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sg.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat.yMMMd().add_jm().format(sg.detectedAt)} · '
                        '${(sg.confidence * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        s.t('farm_advice_from_scan'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ),
                _PriorityBadge(
                  label: _priorityLabel(),
                  color: priorityColor,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                sg.summary,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
            if (sg.actions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                s.t('scan_treatment_suggestions'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...sg.actions.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${e.key + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: priorityColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              e.value,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                height: 1.45,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// ── Scans ─────────────────────────────────────────────────────────────────────

class _ScanTile extends StatelessWidget {
  const _ScanTile({required this.scan, required this.s});
  final DiagnosisResult scan;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd().add_jm().format(scan.createdAt);
    final accent = AppTheme.semanticPositive(healthy: scan.isHealthy);
    final hasImage = File(scan.imagePath).existsSync();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: KulimaCard(
        accentColor: accent,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: SizedBox(
                width: 52,
                height: 52,
                child: hasImage
                    ? Image.file(File(scan.imagePath), fit: BoxFit.cover)
                    : ColoredBox(
                        color: accent.withValues(alpha: 0.1),
                        child: Icon(
                          scan.crop.icon,
                          color: accent,
                          size: 24,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.diseaseLabel(scan.rawDiseaseLabel),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.cropLabel(scan.crop.id)} · $date',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            ConfidenceBadge(
              confidence: scan.confidence,
              isHealthy: scan.isHealthy,
            ),
          ],
        ),
      ),
    );
  }
}
