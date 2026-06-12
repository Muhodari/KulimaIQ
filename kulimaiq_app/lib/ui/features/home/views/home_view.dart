import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/diagnosis_result.dart';
import '../../../../l10n/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/confidence_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/kulima_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../shell/app_shell_view_model.dart';
import '../view_models/home_view_model.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.onScanTap});

  final VoidCallback onScanTap;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final s = vm.strings;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: vm.load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              _HeroBanner(
                greeting: s.t('home_greeting'),
                tagline: s.t('tagline'),
                scanLabel: s.t('home_scan_cta'),
                onScan: widget.onScanTap,
              ),
              const SizedBox(height: AppSpacing.xxl),
              _QuickActions(
                onScan: widget.onScanTap,
                strings: s,
                onClimate: () => context.read<AppShellViewModel>().setTab(2),
                onFarms: () => context.read<AppShellViewModel>().setTab(3),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(title: s.t('home_recent')),
              if (vm.loading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xxxl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (vm.error != null)
                Text(vm.error!, style: const TextStyle(color: AppTheme.error))
              else if (vm.recent.isEmpty)
                EmptyState(
                  icon: Icons.document_scanner_outlined,
                  message: s.t('home_no_history'),
                  actionLabel: s.t('home_scan_cta'),
                  onAction: widget.onScanTap,
                )
              else
                ...vm.recent.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _HistoryTile(result: item, strings: s),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.greeting,
    required this.tagline,
    required this.scanLabel,
    required this.onScan,
  });

  final String greeting;
  final String tagline;
  final String scanLabel;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            tagline,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: onScan,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.textPrimary,
              elevation: 0,
            ),
            icon: const Icon(Icons.camera_alt_rounded),
            label: Text(scanLabel),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onScan,
    required this.strings,
    required this.onClimate,
    required this.onFarms,
  });

  final VoidCallback onScan;
  final VoidCallback onClimate;
  final VoidCallback onFarms;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionChip(
            icon: Icons.camera_alt_rounded,
            label: strings.t('nav_scan'),
            color: AppTheme.primary,
            onTap: onScan,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionChip(
            icon: Icons.cloud_rounded,
            label: strings.t('nav_climate'),
            color: const Color(0xFF0277BD),
            onTap: onClimate,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionChip(
            icon: Icons.landscape_rounded,
            label: strings.t('nav_farms'),
            color: AppTheme.accent,
            onTap: onFarms,
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceCard,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppTheme.border),
            boxShadow: [AppTheme.cardShadow],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.result, required this.strings});

  final DiagnosisResult result;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.MMMd().add_jm().format(result.createdAt);
    final diseaseLabel = strings.diseaseLabel(result.rawDiseaseLabel);
    final cropLabel = strings.cropLabel(result.crop.id);
    final accent =
        result.isHealthy ? AppTheme.success : AppTheme.warning;

    return KulimaCard(
      accentColor: accent,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: SizedBox(
              width: 56,
              height: 56,
              child: File(result.imagePath).existsSync()
                  ? Image.file(File(result.imagePath), fit: BoxFit.cover)
                  : ColoredBox(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      child: const Icon(Icons.eco_rounded, color: AppTheme.primary),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diseaseLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('$cropLabel · $date',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          ConfidenceBadge(
            confidence: result.confidence,
            isHealthy: result.isHealthy,
          ),
        ],
      ),
    );
  }
}
