import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_spacing.dart';

class AppTheme {
  // ── Brand palette (high contrast, readable on light surfaces) ─────────────
  static const Color primary = Color(0xFF1B7A3A);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF0F4D24);
  static const Color accent = Color(0xFF1B7A3A);
  static const Color accentSoft = Color(0xFFE8F3EB);
  static const Color info = Color(0xFF1B7A3A);
  static const Color infoSoft = Color(0xFFE8F3EB);
  static const Color surface = Color(0xFFF6F9F6);
  static const Color surfaceCard = Colors.white;
  static const Color surfaceElevated = Color(0xFFFAFCFA);
  static const Color textPrimary = Color(0xFF142117);
  static const Color textSecondary = Color(0xFF4A5C50);
  static const Color textOnDark = Colors.white;
  static const Color border = Color(0xFFD5E0D8);
  static const Color error = Color(0xFFC62828);
  static const Color success = Color(0xFF1B7A3A);
  static const Color warning = Color(0xFF8B6914);

  /// Soft brand tint for chips, crop tiles, and icon backgrounds.
  static Color get primarySoft => primary.withValues(alpha: 0.10);

  /// Slightly stronger tint for highlighted rows and panels.
  static Color get primarySoftMedium => primary.withValues(alpha: 0.16);

  /// Unified page background gradient (used on shell and detail screens).
  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FBF8), surface],
    stops: [0.0, 0.4],
  );

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primaryDark, primary, primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get infoGradient => primaryGradient;

  static BoxShadow get cardShadow => BoxShadow(
        color: primaryDark.withValues(alpha: 0.06),
        blurRadius: 24,
        offset: const Offset(0, 8),
      );

  static BoxShadow get softShadow => BoxShadow(
        color: primaryDark.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      );

  /// Health / scan confidence — brand green when good, muted amber when caution.
  static Color semanticPositive({bool healthy = true}) =>
      healthy ? primary : warning;

  /// Score ring and health percentage coloring.
  static Color scoreColor(double score) {
    if (score >= 75) return primary;
    if (score >= 50) return warning;
    return error;
  }

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: textOnDark,
      secondary: accent,
      onSecondary: textOnDark,
      tertiary: info,
      onTertiary: textOnDark,
      surface: surfaceCard,
      onSurface: textPrimary,
      error: error,
      outline: border,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: textOnDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textOnDark,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceCard,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnDark,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            color: primary,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textSecondary),
        prefixIconColor: primary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: error),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withValues(alpha: 0.14),
        disabledColor: surface,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        checkmarkColor: primary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: surfaceCard,
        indicatorColor: primary.withValues(alpha: 0.14),
        elevation: 0,
        shadowColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontWeight: FontWeight.w700,
              color: primary,
              fontSize: 12,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 26);
          }
          return const IconThemeData(color: textSecondary, size: 24);
        }),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: primary,
        textColor: textPrimary,
      ),
      textTheme: _textTheme(base.textTheme),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      headlineMedium: base.headlineMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 28,
        height: 1.15,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: textPrimary,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: textPrimary,
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: textSecondary,
        fontSize: 13,
        height: 1.4,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 0.3,
      ),
    );
  }
}
