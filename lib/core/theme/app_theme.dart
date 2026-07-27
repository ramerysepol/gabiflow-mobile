import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

/// Tema do GabiFlow — "Expediente": tinta profunda, folha clara, números
/// tabulares. Suporta dark/light e cor de semente do tenant.
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
    final border =
        isDark ? AppColors.borderSubtleDark : AppColors.borderSubtleLight;

    OutlineInputBorder inputBorder(Color color, double width) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      splashFactory: InkSparkle.splashFactory,
      scaffoldBackgroundColor:
          isDark ? AppColors.neutral50Dark : AppColors.canvasLight,
      textTheme: base,
      // Sub-páginas deslizam da direita (estilo iOS) em ambas plataformas.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.neutral50Dark : AppColors.canvasLight,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.titleMedium?.copyWith(
          fontSize: 17,
          color: cs.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        color: isDark ? AppColors.surfaceElevatedDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: isDark ? BorderSide(color: border) : BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          textStyle: base.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          textStyle: base.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          side: BorderSide(color: cs.primary.withValues(alpha: 0.55)),
          textStyle: base.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceElevatedDark : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 16,
        ),
        border: inputBorder(border, 1),
        enabledBorder: inputBorder(border, 1),
        focusedBorder: inputBorder(cs.primary, 2),
        errorBorder: inputBorder(
          isDark ? AppColors.dangerDark : AppColors.dangerLight,
          1,
        ),
        focusedErrorBorder: inputBorder(
          isDark ? AppColors.dangerDark : AppColors.dangerLight,
          2,
        ),
        floatingLabelStyle: TextStyle(color: cs.primary),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: BorderSide(color: border),
        ),
        backgroundColor:
            isDark ? AppColors.surfaceElevatedDark : Colors.white,
        selectedColor: cs.primary.withValues(alpha: isDark ? 0.28 : 0.12),
        labelStyle: base.labelMedium,
        side: BorderSide(color: border),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
        backgroundColor:
            isDark ? AppColors.surfaceOverlayDark : Colors.white,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceOverlayDark : Colors.white,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        color: isDark ? AppColors.surfaceOverlayDark : Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.25),
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
        backgroundColor: isDark ? AppColors.surfaceOverlayDark : AppColors.ink,
        contentTextStyle: base.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: AppElevation.e2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.fab),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme cs) {
    final inter = GoogleFonts.interTextTheme();
    final spaceGrotesk = GoogleFonts.spaceGroteskTextTheme();
    final onSurface = cs.onSurface;
    final onSurfaceVar = cs.brightness == Brightness.dark
        ? AppColors.neutral600Dark
        : AppColors.neutral600Light;
    const tabular = [FontFeature.tabularFigures()];

    return inter.copyWith(
      // Display — Space Grotesk, números tabulares
      displayLarge: spaceGrotesk.displayLarge?.copyWith(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: onSurface,
        fontFeatures: tabular,
      ),
      displayMedium: spaceGrotesk.displayMedium?.copyWith(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: onSurface,
        fontFeatures: tabular,
      ),
      displaySmall: spaceGrotesk.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: onSurface,
        fontFeatures: tabular,
      ),
      // Headline — Inter semibold, tracking apertado
      headlineLarge: inter.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      headlineMedium: inter.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: onSurface,
      ),
      headlineSmall: inter.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: onSurface,
      ),
      // Title — Inter semibold
      titleLarge: inter.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
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
