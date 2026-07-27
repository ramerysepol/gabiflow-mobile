import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

/// Tema premium do GabiFlow com suporte a dark/light e cor de semente do tenant.
abstract final class AppTheme {
  static ThemeData light({Color seedColor = AppColors.defaultSeed}) {
    final cs = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      surface: AppColors.surfaceDefaultLight,
    );
    return _build(cs, isDark: false);
  }

  static ThemeData dark({Color seedColor = AppColors.defaultSeed}) {
    final cs = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: AppColors.surfaceDefaultDark,
    );
    return _build(cs, isDark: true);
  }

  // Aliases antigos — mantidos para compatibilidade com main.dart
  static ThemeData lightTheme({Color? seedColor}) =>
      light(seedColor: seedColor ?? AppColors.defaultSeed);

  static ThemeData darkTheme({Color? seedColor}) =>
      dark(seedColor: seedColor ?? AppColors.defaultSeed);

  static ThemeData _build(ColorScheme cs, {required bool isDark}) {
    final base = _textTheme(cs);
    final border = isDark ? AppColors.borderSubtleDark : AppColors.borderSubtleLight;

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor:
          isDark ? AppColors.neutral50Dark : AppColors.neutral50Light,
      textTheme: base,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.surfaceDefaultDark : AppColors.surfaceDefaultLight,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: base.titleLarge?.copyWith(color: cs.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: AppElevation.e1,
        surfaceTintColor: cs.primary,
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: base.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: base.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          side: BorderSide(color: cs.primary),
          textStyle: base.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(
            color: isDark ? AppColors.dangerDark : AppColors.dangerLight,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(
            color: isDark ? AppColors.dangerDark : AppColors.dangerLight,
            width: 2,
          ),
        ),
        floatingLabelStyle: TextStyle(color: cs.primary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceDefaultDark : AppColors.surfaceDefaultLight,
        indicatorColor: cs.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          base.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: border,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: AppElevation.e2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.fab),
        ),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme cs) {
    final inter = GoogleFonts.interTextTheme();
    final spaceGrotesk = GoogleFonts.spaceGroteskTextTheme();
    final onSurface = cs.onSurface;
    final onSurfaceVar =
        cs.brightness == Brightness.dark ? AppColors.neutral600Dark : AppColors.neutral600Light;

    return inter.copyWith(
      // Display — Space Grotesk
      displayLarge: spaceGrotesk.displayLarge?.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      displayMedium: spaceGrotesk.displayMedium?.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      displaySmall: spaceGrotesk.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      // Headline — Inter semibold
      headlineLarge: inter.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineMedium: inter.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      headlineSmall: inter.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      // Title — Inter semibold
      titleLarge: inter.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: inter.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      // Body — Inter regular
      bodyLarge: inter.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodyMedium: inter.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodySmall: inter.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: onSurfaceVar,
      ),
      // Label
      labelLarge: inter.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelMedium: inter.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelSmall: inter.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: onSurfaceVar,
      ),
    );
  }
}
