import 'package:flutter/material.dart';
import 'lumma_colors.dart';

/// Famílias de fonte do app (empacotadas em assets/fonts).
abstract class LummaFonts {
  static const sans = 'Geist'; // UI
  static const display = 'Cormorant Garamond'; // marca / títulos
}

abstract class LummaTypography {
  /// Wordmark "LUMMA": Cormorant uppercase, letterSpacing ≈ 0.18em.
  static TextStyle wordmark({
    double fontSize = 26,
    Color color = LummaColors.text,
    FontWeight weight = FontWeight.w300,
  }) =>
      TextStyle(
        fontFamily: LummaFonts.display,
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: fontSize * 0.18,
        height: 1.0,
        color: color,
      );

  /// Título de display (Cormorant bold, line-height curto).
  static TextStyle displayTitle({double fontSize = 30, Color color = LummaColors.text}) =>
      TextStyle(
        fontFamily: LummaFonts.display,
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
        height: 0.98,
        color: color,
      );

  /// TextTheme base em Geist.
  static const TextTheme textTheme = TextTheme(
    headlineLarge: TextStyle(fontFamily: LummaFonts.sans, fontSize: 28, fontWeight: FontWeight.w600, color: LummaColors.text),
    headlineMedium: TextStyle(fontFamily: LummaFonts.sans, fontSize: 22, fontWeight: FontWeight.w600, color: LummaColors.text),
    titleLarge: TextStyle(fontFamily: LummaFonts.sans, fontSize: 18, fontWeight: FontWeight.w600, color: LummaColors.text),
    titleMedium: TextStyle(fontFamily: LummaFonts.sans, fontSize: 16, fontWeight: FontWeight.w500, color: LummaColors.text),
    bodyLarge: TextStyle(fontFamily: LummaFonts.sans, fontSize: 16, color: LummaColors.text),
    bodyMedium: TextStyle(fontFamily: LummaFonts.sans, fontSize: 14, color: LummaColors.text),
    bodySmall: TextStyle(fontFamily: LummaFonts.sans, fontSize: 12, color: LummaColors.textMuted),
    labelLarge: TextStyle(fontFamily: LummaFonts.sans, fontSize: 14, fontWeight: FontWeight.w600),
  );
}
