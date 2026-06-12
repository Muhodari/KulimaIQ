import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/confidence_badge.dart';
import '../../../core/widgets/crop_selector.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/kulima_card.dart';
import '../../../core/widgets/section_header.dart';
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
    final s = vm.strings;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                title: s.t('scan_title'),
                subtitle: s.t('scan_subtitle'),
              ),
              Text(
                s.t('scan_select_crop'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              CropSelector(
                selected: vm.selectedCrop,
                onSelected: vm.selectCrop,
                strings: s,
              ),
              const SizedBox(height: AppSpacing.xxl),
              _ImagePreview(path: vm.imagePath),
              const SizedBox(height: AppSpacing.lg),
              if (!vm.loadingCapabilities && !vm.cameraSupported)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppTheme.accentSoft,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppTheme.accent, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            s.t('scan_camera_unavailable_hint'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
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
                          : () => vm.pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: Text(s.t('scan_take_photo')),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: vm.analyzing
                          ? null
                          : () => vm.pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: Text(s.t('scan_gallery')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: vm.analyzing ? null : vm.analyze,
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
              if (vm.error != null && vm.error!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                ErrorBanner(message: vm.error!),
              ],
              if (vm.result != null) ...[
                const SizedBox(height: AppSpacing.xxl),
                _ResultCard(viewModel: vm),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final hasImage = path != null;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: hasImage ? AppTheme.primary : AppTheme.border,
            width: hasImage ? 2 : 1.5,
          ),
          boxShadow: hasImage ? [AppTheme.cardShadow] : null,
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
                child: Image.file(File(path!), fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_rounded,
                    size: 48,
                    color: AppTheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'KulimaIQ · AI Scan',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.viewModel});

  final ScanViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final result = viewModel.result!;
    final s = viewModel.strings;
    final isHealthy = result.isHealthy;
    final accent = isHealthy ? AppTheme.success : AppTheme.warning;

    return KulimaCard(
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isHealthy
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  color: accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  s.diseaseLabel(result.rawDiseaseLabel),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ConfidenceBadge(
                confidence: result.confidence,
                isHealthy: isHealthy,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _MetaRow(
            icon: Icons.wifi_tethering_rounded,
            label: result.isOffline ? s.t('scan_offline') : s.t('scan_online'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              result.recommendation ??
                  s.recommendation(result.recommendationKey ?? 'rec_healthy'),
              style: const TextStyle(height: 1.5, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
