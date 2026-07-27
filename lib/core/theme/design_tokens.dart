import 'package:flutter/material.dart';

/// Tokens de design do GabiFlow — sistema agnóstico de tenant.
/// Cores de marca vêm do ColorScheme gerado por seedColor.
abstract final class AppColors {
  // --- Neutros Light ---
  static const neutral50Light = Color(0xFFF8FAFC);
  static const neutral100Light = Color(0xFFF1F5F9);
  static const neutral200Light = Color(0xFFE2E8F0);
  static const neutral300Light = Color(0xFFCBD5E1);
  static const neutral600Light = Color(0xFF475569);
  static const neutral700Light = Color(0xFF334155);
  static const neutral900Light = Color(0xFF0F172A);

  // --- Neutros Dark ---
  static const neutral50Dark = Color(0xFF0F1117);
  static const neutral100Dark = Color(0xFF161B26);
  static const neutral200Dark = Color(0xFF1E2534);
  static const neutral300Dark = Color(0xFF2A3344);
  static const neutral600Dark = Color(0xFF94A3B8);
  static const neutral700Dark = Color(0xFFCBD5E1);
  static const neutral900Dark = Color(0xFFF8FAFC);

  // --- Superfícies Light ---
  static const surfaceDefaultLight = Color(0xFFFFFFFF);
  static const surfaceElevatedLight = Color(0xFFF8FAFC);
  static const surfaceOverlayLight = Color(0xFFFFFFFF);
  static const borderSubtleLight = Color(0xFFE2E8F0);
  static const borderDefaultLight = Color(0xFFCBD5E1);

  // --- Superfícies Dark ---
  static const surfaceDefaultDark = Color(0xFF1A2030);
  static const surfaceElevatedDark = Color(0xFF202839);
  static const surfaceOverlayDark = Color(0xFF252F42);
  static const borderSubtleDark = Color(0xFF2A3344);
  static const borderDefaultDark = Color(0xFF3A4556);

  // --- Semânticas ---
  static const successLight = Color(0xFF16A34A);
  static const successDark = Color(0xFF4ADE80);
  static const successContainerLight = Color(0xFFDCFCE7);
  static const successContainerDark = Color(0xFF14532D);

  static const warningLight = Color(0xFFD97706);
  static const warningDark = Color(0xFFFCD34D);
  static const warningContainerLight = Color(0xFFFEF3C7);
  static const warningContainerDark = Color(0xFF451A03);

  static const dangerLight = Color(0xFFDC2626);
  static const dangerDark = Color(0xFFF87171);
  static const dangerContainerLight = Color(0xFFFEE2E2);
  static const dangerContainerDark = Color(0xFF450A0A);

  static const infoLight = Color(0xFF0284C7);
  static const infoDark = Color(0xFF38BDF8);
  static const infoContainerLight = Color(0xFFE0F2FE);
  static const infoContainerDark = Color(0xFF0C2A3E);

  /// Cor de semente padrão — pode ser substituída por cor do tenant.
  static const defaultSeed = Color(0xFF2563EB);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double screenH = 20;
  static const double screenV = 24;
}

abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double card = 12;
  static const double cardLarge = 16;
  static const double modal = 20;
  static const double fab = 16;
  static const double full = 9999;
}

abstract final class AppElevation {
  static const double e0 = 0;
  static const double e1 = 1;
  static const double e2 = 2;
  static const double e3 = 3;
}

/// Curvas e durações de animação.
abstract final class AppMotion {
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration emphasized = Duration(milliseconds: 300);
  static const Duration decelerate = Duration(milliseconds: 250);
  static const Duration accelerate = Duration(milliseconds: 150);

  static const Curve standardCurve = Curves.easeInOut;
  static const Curve emphasizedCurve = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve decelerateCurve = Curves.easeOut;
  static const Curve accelerateCurve = Curves.easeIn;
}
