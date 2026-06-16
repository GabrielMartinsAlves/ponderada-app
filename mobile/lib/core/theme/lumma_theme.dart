import 'package:flutter/material.dart';
import 'lumma_colors.dart';
import 'lumma_typography.dart';

/// ThemeData do app a partir dos tokens Lumma.
abstract class LummaTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: LummaColors.mauve,
      brightness: Brightness.light,
    ).copyWith(
      primary: LummaColors.mauve,
      onPrimary: Colors.white,
      secondary: LummaColors.mauveDark,
      surface: LummaColors.card,
      onSurface: LummaColors.text,
      error: LummaColors.errorText,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: LummaColors.background,
      colorScheme: scheme,
      fontFamily: LummaFonts.sans,
      textTheme: LummaTypography.textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: LummaColors.background,
        foregroundColor: LummaColors.text,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: LummaColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // rounded-2xl
          side: const BorderSide(color: LummaColors.borderLight),
        ),
        shadowColor: const Color(0x143D2B35),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LummaColors.mauve,
          foregroundColor: Colors.white,
          disabledBackgroundColor: LummaColors.mauve500,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontFamily: LummaFonts.sans, fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(LummaColors.mauveDark), // hover/pressed -> dark
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LummaColors.mauve,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: LummaColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: LummaColors.mauveDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LummaColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: LummaColors.textFaint),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LummaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LummaColors.mauve, width: 1.6),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: LummaColors.card,
        selectedItemColor: LummaColors.mauve,
        unselectedItemColor: LummaColors.textFaint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      dividerTheme: const DividerThemeData(color: LummaColors.borderLight, thickness: 1),
      chipTheme: const ChipThemeData(
        backgroundColor: LummaColors.cream,
        labelStyle: TextStyle(color: LummaColors.mauveDark, fontFamily: LummaFonts.sans),
        side: BorderSide(color: LummaColors.borderLight),
      ),
    );
  }
}
