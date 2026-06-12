import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/climate_advisory.dart';
import '../../../../l10n/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/kulima_card.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/section_header.dart';
import '../view_models/climate_view_model.dart';
import '../../../shell/app_shell_view_model.dart';

class ClimateView extends StatefulWidget {
  const ClimateView({super.key});

  @override
  State<ClimateView> createState() => _ClimateViewState();
}

class _ClimateViewState extends State<ClimateView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClimateViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClimateViewModel>();
    final s = vm.strings;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!vm.isOnline)
              OfflineBanner(message: s.t('climate_offline_note')),
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: vm.load,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  children: [
                    SectionHeader(
                      title: s.t('climate_title'),
                      subtitle: vm.isOnline
                          ? s.t('climate_subtitle_live')
                          : s.t('climate_offline_note'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (vm.error != null)
                      Text(vm.error!,
                          style: const TextStyle(color: AppTheme.error))
                    else if (!vm.isOnline)
                      _OfflineEmptyState(strings: s)
                    else if (vm.noLocations)
                      _NoLocationsEmptyState(strings: s)
                    else if (vm.advisories.isEmpty)
                      _AllClearCard(strings: s)
                    else
                      ...vm.advisories.map(
                        (a) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _AdvisoryCard(advisory: a),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Empty states ──────────────────────────────────────────────────────────────

class _OfflineEmptyState extends StatelessWidget {
  const _OfflineEmptyState({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      message: strings.t('climate_offline_note'),
    );
  }
}

class _NoLocationsEmptyState extends StatelessWidget {
  const _NoLocationsEmptyState({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.location_off_outlined,
      message: strings.t('climate_no_farms_gps'),
      actionLabel: strings.t('nav_farms'),
      onAction: () => context.read<AppShellViewModel>().setTab(3),
    );
  }
}

class _AllClearCard extends StatelessWidget {
  const _AllClearCard({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return KulimaCard(
      accentColor: AppTheme.success,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: AppTheme.success, size: 28),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.t('climate_all_clear_title'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  strings.t('climate_all_clear_body'),
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Advisory card ─────────────────────────────────────────────────────────────

class _AdvisoryCard extends StatelessWidget {
  const _AdvisoryCard({required this.advisory});
  final ClimateAdvisory advisory;

  Color _severityColor() {
    switch (advisory.severity) {
      case AdvisorySeverity.low:
        return AppTheme.success;
      case AdvisorySeverity.medium:
        return AppTheme.warning;
      case AdvisorySeverity.high:
        return AppTheme.error;
    }
  }

  String _severityLabel() {
    switch (advisory.severity) {
      case AdvisorySeverity.low:
        return 'Low';
      case AdvisorySeverity.medium:
        return 'Medium';
      case AdvisorySeverity.high:
        return 'High';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.MMMd();
    final range =
        '${fmt.format(advisory.validFrom)} – ${fmt.format(advisory.validTo)}';
    final color = _severityColor();

    return KulimaCard(
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(advisory.icon, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      advisory.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _severityLabel(),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            advisory.body,
            style: const TextStyle(height: 1.5, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.place_outlined,
                  size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${advisory.location} · $range',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
