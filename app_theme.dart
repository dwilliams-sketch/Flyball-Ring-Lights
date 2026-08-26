import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF080B10);
  static const surface = Color(0xFF121821);
  static const surface2 = Color(0xFF1A2230);
  static const border = Color(0xFF303B4B);
  static const textMuted = Color(0xFF98A6B8);
  static const gold = Color(0xFFE0AF45);
  static const blueLane = Color(0xFF2387E8);
  static const redLane = Color(0xFFE24848);
  static const green = Color(0xFF42E36E);

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(primary: gold, secondary: blueLane, surface: surface, error: redLane),
    cardTheme: CardThemeData(color: surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: border))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: gold, width: 1.4)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .6))),
  );
}
