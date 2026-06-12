import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 56,
    this.showLabel = true,
    this.light = false,
  });

  final double size;
  final bool showLabel;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final textColor = light ? Colors.white : AppTheme.textPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: light
                ? LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.1),
                    ],
                  )
                : AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            boxShadow: light
                ? null
                : [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Icon(
            Icons.eco_rounded,
            color: light ? Colors.white : Colors.white,
            size: size * 0.55,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: AppSpacing.md),
          Text(
            'KulimaIQ',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}
