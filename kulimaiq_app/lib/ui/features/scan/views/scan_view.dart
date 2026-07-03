import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/crop_selector.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/kulima_card.dart';
import '../../../core/widgets/step_section.dart';
import '../view_models/scan_view_model.dart';

class ScanView extends StatefulWidget {
  const ScanView({super.key});

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanViewModel>().loadCapabilities();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScanViewModel>();

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (vm.result != null && !vm.analyzing) {
          return _ScanResultView(vm: vm);
        }
        return _ScanInputView(vm: vm);
      },
    );
  }
}

// ── Input flow ────────────────────────────────────────────────────────────────

class _ScanInputView extends StatelessWidget {
  const _ScanInputView({required this.vm});
  final ScanViewModel vm;

  @override
  Widget build(BuildContext context) {
    final s = vm.strings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.t('scan_title'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            s.t('scan_subtitle'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (vm.isFarmScan) ...[
            const SizedBox(height: AppSpacing.lg),
            _FarmContextBanner(vm: vm, strings: s),
          ],
          const SizedBox(height: AppSpacing.lg),
          KulimaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StepSection(
                  step: 1,
                  title: vm.isFarmScan
                      ? s.t('scan_select_farm_crop')
                      : s.t('scan_step_crop'),
                  subtitle: s.t('scan_step_crop_sub'),
                  child: vm.isFarmScan && !vm.hasFarmCrops
                      ? _NoCropsWarning(strings: s)
                      : CropSelector(
                          selected: vm.selectedCrop,
                          onSelected: vm.selectCrop,
                          strings: s,
                          allowedCrops:
                              vm.hasFarmCrops ? vm.farmCrops : null,
                        ),
                ),
                StepSection(
                  step: 2,
                  title: s.t('scan_step_photo'),
                  subtitle: s.t('scan_step_photo_sub'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ImagePreview(
                        path: vm.imagePath,
                        compact: true,
                        placeholder: s.t('scan_placeholder'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (!vm.loadingCapabilities && !vm.cameraSupported)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _InfoBanner(
                            message: s.t('scan_camera_unavailable_hint'),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: vm.analyzing ||
                                      vm.loadingCapabilities ||
                                      !vm.cameraSupported
                                  ? null
                                  : () =>
                                      vm.pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_rounded),
                              label: Text(s.t('scan_take_photo')),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: vm.analyzing
                                  ? null
                                  : () =>
                                      vm.pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_rounded),
                              label: Text(s.t('scan_gallery')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                StepSection(
                  step: 3,
                  title: s.t('scan_step_analyze'),
                  isLast: true,
                  child: FilledButton(
                    onPressed: (vm.analyzing ||
                            (vm.isFarmScan && !vm.hasFarmCrops))
                        ? null
                        : vm.analyze,
                    child: vm.analyzing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(s.t('scan_analyzing')),
                            ],
                          )
                        : Text(s.t('scan_analyze')),
                  ),
                ),
              ],
            ),
          ),
          if (vm.error != null && vm.error!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            ErrorBanner(message: vm.error!),
          ],
        ],
      ),
    );
  }
}

// ── Result flow (no scroll needed for main finding) ───────────────────────────

class _ScanResultView extends StatelessWidget {
  const _ScanResultView({required this.vm});
  final ScanViewModel vm;

  @override
  Widget build(BuildContext context) {
    final s = vm.strings;
    final result = vm.result!;
    final isHealthy = result.isHealthy;
    final accent = AppTheme.semanticPositive(healthy: isHealthy);
    final diseaseLabel = s.diseaseLabel(result.rawDiseaseLabel);
    final cropLabel = s.cropLabel(vm.selectedCrop.id);
    final recommendation = result.recommendation ??
        s.recommendation(result.recommendationKey ?? 'rec_healthy');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: isHealthy
                        ? AppTheme.primaryGradient
                        : LinearGradient(
                            colors: [
                              AppTheme.warning.withValues(alpha: 0.9),
                              AppTheme.warning,
                            ],
                          ),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [AppTheme.cardShadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (vm.imagePath != null)
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: Image.file(
                                  File(vm.imagePath!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          if (vm.imagePath != null)
                            const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cropLabel,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  diseaseLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        recommendation,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(
                            result.isOffline
                                ? Icons.cloud_off_rounded
                                : Icons.cloud_done_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            result.isOffline
                                ? s.t('scan_offline')
                                : s.t('scan_online'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (result.actions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: SingleChildScrollView(
                      child: KulimaCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.t('scan_treatment_suggestions'),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...result.actions.asMap().entries.map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppSpacing.sm),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: accent.withValues(
                                                alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${e.key + 1}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: accent,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                            width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            e.value,
                                            style: const TextStyle(
                                              height: 1.45,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: vm.startNewScan,
            icon: const Icon(Icons.camera_alt_rounded),
            label: Text(s.t('scan_again')),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _FarmContextBanner extends StatelessWidget {
  const _FarmContextBanner({required this.vm, required this.strings});
  final ScanViewModel vm;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return KulimaCard(
      child: Row(
        children: [
          const Icon(Icons.landscape_rounded,
              color: AppTheme.primary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.t('farm_scan_for'),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
                Text(
                  vm.farmName ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: vm.clearFarmContext,
            child: Text(strings.t('farm_scan_clear')),
          ),
        ],
      ),
    );
  }
}

class _NoCropsWarning extends StatelessWidget {
  const _NoCropsWarning({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppTheme.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              strings.t('scan_farm_no_crops'),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.primarySoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppTheme.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    this.path,
    required this.placeholder,
    this.compact = false,
  });

  final String? path;
  final String placeholder;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasImage = path != null;
    final height = compact ? 140.0 : 200.0;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: hasImage ? AppTheme.primary : AppTheme.border,
            width: hasImage ? 2 : 1,
          ),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm - 2),
                child: Image.file(File(path!), fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_rounded,
                    size: compact ? 32 : 40,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    placeholder,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
