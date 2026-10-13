import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.terracotta,
        surface: AppColors.paper,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme),
    );
  }

  /// Headings use Fraunces.
  static TextStyle heading(double size, {Color color = AppColors.text}) {
    return GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }

  /// Everything else uses Manrope.
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.text,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }
}
