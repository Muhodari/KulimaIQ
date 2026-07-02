import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Numbered step block — use to show clear order on multi-step screens.
class StepSection extends StatelessWidget {
  const StepSection({
    super.key,
    required this.step,
    required this.title,
    required this.child,
    this.subtitle,
    this.isLast = false,
  });

  final int step;
  final String title;
  final String? subtitle;
  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepBadge(number: step),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: child,
        ),
        if (!isLast) ...[
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Container(
              height: 1,
              color: AppTheme.border,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          color: AppTheme.textOnDark,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}
