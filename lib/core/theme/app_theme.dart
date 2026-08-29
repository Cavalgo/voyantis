import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema de Voyantis — editorial / cálido, pensado para que el timeline del
/// itinerario se vea "aesthetic" en proyector.
///
/// - Cuerpo: Inter (legible, neutra).
/// - Títulos / hero: Fraunces (serif con carácter, para el toque editorial).
class AppColors {
  static const cream = Color(0xFFF7F3EC);
  static const sand = Color(0xFFEFE7DA);
  static const ink = Color(0xFF2B2622);
  static const sienna = Color(0xFFB5623C);
  static const siennaDark = Color(0xFF8F4A2C);
  static const sage = Color(0xFF7C8A6B);
  static const gold = Color(0xFFC9A24B);
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFF8A8178);
  static const line = Color(0xFFE3DACB);
}

/// Fuente para títulos grandes / hero del itinerario.
TextStyle displayFont({
  double? fontSize,
  FontWeight fontWeight = FontWeight.w600,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.fraunces(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.sienna,
      primary: AppColors.sienna,
      secondary: AppColors.sage,
      surface: AppColors.cream,
    ),
    scaffoldBackgroundColor: AppColors.cream,
  );

  final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  ).copyWith(
    displayLarge: displayFont(color: AppColors.ink),
    displayMedium: displayFont(color: AppColors.ink),
    displaySmall: displayFont(color: AppColors.ink),
    headlineMedium: displayFont(color: AppColors.ink),
    headlineSmall: displayFont(color: AppColors.ink),
    titleLarge: displayFont(color: AppColors.ink, fontWeight: FontWeight.w600),
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.sand,
      side: const BorderSide(color: AppColors.line),
      labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.ink),
      shape: const StadiumBorder(),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
  );
}
