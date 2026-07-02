import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../shell/app_shell_view_model.dart';
import '../../../shell/locale_view_model.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleViewModel>();
    final shell = context.read<AppShellViewModel>();
    final s = locale.strings;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: BrandLogo(size: 44),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                s.t('onboarding_title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                s.t('onboarding_body'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xxl),
              ...[
                (Icons.camera_alt_rounded, s.t('onboarding_feature_scan')),
                (Icons.cloud_rounded, s.t('onboarding_feature_weather')),
                (Icons.landscape_rounded, s.t('onboarding_feature_farms')),
              ].map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Icon(item.$1, color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Text(
                          item.$2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                s.t('profile_language_hint'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              FilledButton(
                onPressed: shell.completeOnboarding,
                child: Text(s.t('onboarding_start')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
