import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

class KulimaCard extends StatelessWidget {
  const KulimaCard({
    super.key,
    required this.child,
    this.padding,
    this.accentColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      child: child,
    );

    final card = Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: accentColor?.withValues(alpha: 0.28) ?? AppTheme.border,
          width: accentColor != null ? 1.5 : 1,
        ),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: accentColor != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: accentColor),
                    Expanded(child: content),
                  ],
                ),
              ),
            )
          : content,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: card,
      ),
    );
  }
}
