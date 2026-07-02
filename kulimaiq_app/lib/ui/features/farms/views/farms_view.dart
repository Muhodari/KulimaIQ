import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/crop_type.dart';
import '../../../../domain/models/farm.dart';
import '../../../../l10n/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/kulima_card.dart';
import '../../../core/widgets/section_header.dart';
import '../view_models/farm_view_model.dart';
import 'farm_detail_page.dart';
import 'farm_form_sheet.dart';

class FarmsView extends StatefulWidget {
  const FarmsView({super.key});

  @override
  State<FarmsView> createState() => _FarmsViewState();
}

class _FarmsViewState extends State<FarmsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmViewModel>().load();
    });
  }

  void _openAddSheet() {
    final vm = context.read<FarmViewModel>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: const FarmFormSheet(),
      ),
    );
  }

  List<Widget> _buildFarmList(FarmViewModel vm) {
    return [
      for (final farm in vm.farms)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _FarmCard(farm: farm, vm: vm),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FarmViewModel>();
    final s = vm.strings;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return Stack(
          children: [
            vm.loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: vm.load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        AppSpacing.screenPadding,
                        AppSpacing.screenPadding,
                        100,
                      ),
                      children: [
                        SectionHeader(
                          title: s.t('farm_list_title'),
                          subtitle: s.t('farm_list_subtitle'),
                        ),
                        if (!vm.loading && vm.farms.isNotEmpty) ...[
                          _OverallHealthCard(vm: vm),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                        if (vm.error != null)
                          Text(vm.error!,
                              style: const TextStyle(color: AppTheme.error))
                        else if (vm.farms.isEmpty)
                          EmptyState(
                            icon: Icons.landscape_outlined,
                            message: s.t('farm_empty'),
                            actionLabel: s.t('farm_add'),
                            onAction: _openAddSheet,
                          )
                        else
                          ..._buildFarmList(vm),
                      ],
                    ),
                  ),
            Positioned(
              right: AppSpacing.screenPadding,
              bottom: AppSpacing.lg,
              child: FloatingActionButton.extended(
                onPressed: _openAddSheet,
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.textOnDark,
                elevation: 4,
                icon: const Icon(Icons.add_rounded),
                label: Text(s.t('farm_add')),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Overall health summary card ───────────────────────────────────────────────

class _OverallHealthCard extends StatelessWidget {
  const _OverallHealthCard({required this.vm});
  final FarmViewModel vm;

  @override
  Widget build(BuildContext context) {
    final s = vm.strings;
    final score = vm.overallScore;
    final color = _scoreColor(score);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.landscape_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text(
                s.t('farm_overall_title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score == null
                          ? s.t('farm_no_data')
                          : '${score.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 44,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      score == null
                          ? s.t('farm_scan_hint')
                          : _scoreLabel(score, s),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (score != null) _CircleScore(score: score, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _StatBadge(
                label: s.t('farm_stat_total'),
                value: '${vm.farmCount}',
              ),
              const SizedBox(width: AppSpacing.md),
              _StatBadge(
                label: s.t('farm_stat_healthy'),
                value: '${vm.healthyCount}',
              ),
              const SizedBox(width: AppSpacing.md),
              _StatBadge(
                label: s.t('farm_stat_at_risk'),
                value: '${vm.atRiskCount}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _scoreColor(double? score) {
    if (score == null) return AppTheme.textSecondary;
    return AppTheme.scoreColor(score);
  }

  String _scoreLabel(double score, dynamic s) {
    if (score >= 75) return s.t('farm_health_good');
    if (score >= 50) return s.t('farm_health_moderate');
    return s.t('farm_health_poor');
  }
}

class _CircleScore extends StatelessWidget {
  const _CircleScore({required this.score, required this.color});
  final double score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 8,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Center(
            child: Text(
              '${score.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Farm card ────────────────────────────────────────────────────────────────

class _FarmCard extends StatelessWidget {
  const _FarmCard({
    required this.farm,
    required this.vm,
  });
  final Farm farm;
  final FarmViewModel vm;

  @override
  Widget build(BuildContext context) {
    final s = vm.strings;
    final statusColor = _statusColor(farm.healthStatus);
    final lastScan = farm.lastScannedAt != null
        ? DateFormat.MMMd().format(farm.lastScannedAt!)
        : s.t('farm_never_scanned');

    return KulimaCard(
      accentColor: statusColor,
      onTap: () => _showDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(Icons.landscape_rounded,
                    color: statusColor, size: 26),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  farm.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (farm.healthScore != null)
                _ScorePill(score: farm.healthScore!, color: statusColor),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(
                icon: Icons.straighten_rounded,
                label: '${farm.sizeHa} ha',
              ),
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: lastScan,
              ),
              _StatusChip(status: farm.healthStatus, strings: s),
              ...farm.crops.map(
                (c) => _InfoChip(
                  icon: _cropIcon(c),
                  label: s.cropLabel(c.id),
                ),
              ),
            ],
          ),
          if (farm.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              farm.notes,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FarmDetailPage(farm: farm),
      ),
    );
  }

  Color _statusColor(FarmHealthStatus status) {
    switch (status) {
      case FarmHealthStatus.healthy:
        return AppTheme.primary;
      case FarmHealthStatus.atRisk:
        return AppTheme.warning;
      case FarmHealthStatus.diseased:
        return AppTheme.error;
      case FarmHealthStatus.unknown:
        return AppTheme.textSecondary;
    }
  }

  IconData _cropIcon(CropType crop) => crop.icon;
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score, required this.color});
  final double score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${score.toStringAsFixed(0)}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.strings});
  final FarmHealthStatus status;
  final dynamic strings;

  @override
  Widget build(BuildContext context) {
    String key;
    Color color;
    switch (status) {
      case FarmHealthStatus.healthy:
        key = 'farm_status_healthy';
        color = AppTheme.primary;
      case FarmHealthStatus.atRisk:
        key = 'farm_status_at_risk';
        color = AppTheme.warning;
      case FarmHealthStatus.diseased:
        key = 'farm_status_diseased';
        color = AppTheme.error;
      case FarmHealthStatus.unknown:
        key = 'farm_status_unknown';
        color = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        strings.t(key),
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
