import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_spacing.dart';

class AppTheme {
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF43A047);
  static const Color primaryDark = Color(0xFF0D3D12);
  static const Color accent = Color(0xFFFF8F00);
  static const Color accentSoft = Color(0xFFFFF3E0);
  static const Color surface = Color(0xFFF7F9F7);
  static const Color surfaceCard = Colors.white;
  static const Color textPrimary = Color(0xFF1A211C);
  static const Color textSecondary = Color(0xFF5F6B63);
  static const Color border = Color(0xFFE2EAE4);
  static const Color error = Color(0xFFC62828);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE65100);

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [primary, primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static BoxShadow get cardShadow => BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      );

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: textPrimary,
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
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
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
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border, width: 1.5),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7)),
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
        selectedColor: primary.withValues(alpha: 0.12),
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: surfaceCard,
        indicatorColor: primary.withValues(alpha: 0.12),
        elevation: 8,
        shadowColor: Colors.black26,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontWeight: FontWeight.w600,
              color: primary,
              fontSize: 11,
            );
          }
          return const TextStyle(fontSize: 11, color: textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: textSecondary, size: 24);
        }),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      textTheme: _textTheme(base.textTheme),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      headlineMedium: base.headlineMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 26,
        height: 1.2,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: textPrimary,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: textSecondary,
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: textSecondary,
        fontSize: 12,
        height: 1.4,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
