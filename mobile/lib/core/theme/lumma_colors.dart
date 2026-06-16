import 'package:flutter/material.dart';

/// Paleta Lumma — valores EXATOS do design system (não aproximar).
abstract class LummaColors {
  // ── Backgrounds ──
  static const background = Color(0xFFF8F2EE);
  static const card = Color(0xFFFFFFFF);
  static const cream = Color(0xFFF9E5DB);
  static const pink = Color(0xFFF0CAD3);
  static const rose = Color(0xFFE0BAB2);
  static const sage = Color(0xFFDAE2DC);

  // ── Marca (Brandbook) ──
  static const mauve = Color(0xFF998289);
  static const mauveDark = Color(0xFF7A6470);
  static const sageDark = Color(0xFF5C7460);

  // ── Texto ──
  static const text = Color(0xFF3D2B35);
  static const textMuted = Color(0xFF7A6470);
  static const textFaint = Color(0xFF998289);
  static const textOnDark = Color(0xFFF9E5DB);

  // ── Semânticos ──
  static const border = Color(0xFFE0BAB2);
  static const borderLight = Color(0x66E0BAB2); // rgba(224,186,178,0.40)
  static const focusRing = Color(0x66998289); // rgba(153,130,137,0.40)
  static const successBg = Color(0xFFDAE2DC);
  static const successText = Color(0xFF5C7460);
  static const errorBg = Color(0xFFF9E5DB);
  static const errorText = Color(0xFF7A6470);

  // ── Escala mauve 100–900 ──
  static const mauve100 = Color(0xFFF8F2EE);
  static const mauve200 = Color(0xFFF9E5DB);
  static const mauve300 = Color(0xFFF0CAD3);
  static const mauve400 = Color(0xFFE0BAB2);
  static const mauve500 = Color(0xFFC4AAB0);
  static const mauve600 = Color(0xFFB09A9F);
  static const mauve700 = Color(0xFF998289);
  static const mauve800 = Color(0xFF7A6470);
  static const mauve900 = Color(0xFF3D2B35);
}
