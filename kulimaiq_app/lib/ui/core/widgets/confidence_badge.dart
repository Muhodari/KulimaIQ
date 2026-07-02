import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({
    super.key,
    required this.confidence,
    required this.isHealthy,
  });

  final double confidence;
  final bool isHealthy;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.semanticPositive(healthy: isHealthy);
    final percent = (confidence * 100).round();

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
        '$percent%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}
