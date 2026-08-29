import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema base de Voyantis — editorial / cálido, pensado para que el timeline
/// del itinerario se vea "aesthetic" en proyector. Track B lo afina.
class AppColors {
  static const cream = Color(0xFFF7F3EC);
  static const ink = Color(0xFF2B2622);
  static const sienna = Color(0xFFB5623C);
  static const sage = Color(0xFF7C8A6B);
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFF8A8178);
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

  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
