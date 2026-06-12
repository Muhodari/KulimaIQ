import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/crop_type.dart';
import '../../../../domain/models/farm.dart';
import '../../../../domain/models/farm_weather.dart';
import '../../../../l10n/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/kulima_card.dart';
import '../../../core/widgets/section_header.dart';
import '../view_models/farm_view_model.dart';
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FarmFormSheet(),
    );
  }

  List<Widget> _buildGroupedFarms(FarmViewModel vm) {
    final widgets = <Widget>[];
    final grouped = vm.farmsByCountry;
    for (final country in vm.activeCountries) {
      final farmsInCountry = grouped[country]!;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _CountryHeader(country: country),
        ),
      );
      for (final farm in farmsInCountry) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _FarmCard(
              farm: farm,
              vm: vm,
              weather: vm.weatherFor(farm.id),
            ),
          ),
        );
      }
      widgets.add(const SizedBox(height: AppSpacing.md));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FarmViewModel>();
    final s = vm.strings;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.surface,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openAddSheet,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(s.t('farm_add')),
          ),
          body: vm.loading
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
                      _OverallHealthCard(vm: vm),
                      const SizedBox(height: AppSpacing.xxl),
                      SectionHeader(
                        title: s.t('farm_list_title'),
                        subtitle: s.t('farm_list_subtitle'),
                      ),
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
                        ..._buildGroupedFarms(vm),
                    ],
                  ),
                ),
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
                color: Colors.greenAccent.shade400,
              ),
              const SizedBox(width: AppSpacing.md),
              _StatBadge(
                label: s.t('farm_stat_at_risk'),
                value: '${vm.atRiskCount}',
                color: Colors.orange.shade300,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _scoreColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 75) return Colors.greenAccent.shade400;
    if (score >= 50) return Colors.orange;
    return Colors.redAccent;
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
  const _StatBadge({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

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
            style: TextStyle(
              color: color ?? Colors.white,
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

// ── Country section header ────────────────────────────────────────────────────

class _CountryHeader extends StatelessWidget {
  const _CountryHeader({required this.country});
  final String country;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.public_rounded, size: 14, color: AppTheme.primary),
              const SizedBox(width: 4),
              Text(
                country,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Farm card ────────────────────────────────────────────────────────────────

class _FarmCard extends StatelessWidget {
  const _FarmCard({
    required this.farm,
    required this.vm,
    this.weather,
  });
  final Farm farm;
  final FarmViewModel vm;
  final FarmWeather? weather;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (farm.locationDisplay.isNotEmpty)
                      Text(
                        farm.locationDisplay,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (farm.healthScore != null)
                _ScorePill(score: farm.healthScore!, color: statusColor),
            ],
          ),
          // ── Weather strip ─────────────────────────────────────────────
          if (weather != null) ...[
            const SizedBox(height: AppSpacing.md),
            _WeatherStrip(weather: weather!),
          ] else if (farm.hasCoordinates) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 13, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  s.t('farm_weather_offline'),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.location_off_outlined,
                    size: 13, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  s.t('farm_no_gps'),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FarmFormSheet(farm: farm),
    );
  }

  Color _statusColor(FarmHealthStatus status) {
    switch (status) {
      case FarmHealthStatus.healthy:
        return AppTheme.success;
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

// ── Weather strip ─────────────────────────────────────────────────────────────

class _WeatherStrip extends StatelessWidget {
  const _WeatherStrip({required this.weather});
  final FarmWeather weather;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0369A1).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Icon(weather.icon, size: 18, color: const Color(0xFF0369A1)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${weather.temperatureC.toStringAsFixed(1)}°C',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF0369A1),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              weather.description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF0369A1),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.air_rounded,
                  size: 13, color: const Color(0xFF0369A1).withValues(alpha: 0.6)),
              const SizedBox(width: 2),
              Text(
                '${weather.windspeedKmh.toStringAsFixed(0)} km/h',
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF0369A1).withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
        color = AppTheme.success;
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
