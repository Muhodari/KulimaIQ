import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../../shell/locale_view_model.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    this.compact = false,
    this.showHint = false,
    this.onDark = false,
  });

  final bool compact;
  final bool showHint;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final localeVm = context.watch<LocaleViewModel>();
    final s = localeVm.strings;

    final options = <String, String>{
      'en': s.t('lang_en'),
      'rw': s.t('lang_rw'),
    };

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: onDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: onDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : AppTheme.border,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: localeVm.locale,
                dropdownColor: AppTheme.surfaceCard,
                style: TextStyle(
                  color: onDark ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                icon: Icon(
                  Icons.language_rounded,
                  color: onDark ? Colors.white : AppTheme.primary,
                  size: 20,
                ),
                items: options.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: (code) {
                  if (code != null) localeVm.setLocale(code);
                },
              ),
            ),
          ),
          if (showHint) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: 220,
              child: Text(
                s.t('profile_language_hint'),
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: onDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppTheme.textSecondary,
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.language_rounded, size: 18, color: AppTheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              s.t('profile_language'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<String>(
          segments: options.entries
              .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
              .toList(),
          selected: {localeVm.locale},
          onSelectionChanged: (set) => localeVm.setLocale(set.first),
        ),
        if (showHint) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(s.t('profile_language_hint'),
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
