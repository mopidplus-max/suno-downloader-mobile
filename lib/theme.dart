import 'package:flutter/material.dart';

class AppTheme {
  static const ink = Color(0xFF101412);
  static const paper = Color(0xFFF4F2EA);
  static const card = Color(0xFFFFFFFF);
  static const lime = Color(0xFFB8F34A);
  static const muted = Color(0xFF737A75);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: ink,
      onPrimary: paper,
      secondary: lime,
      onSecondary: ink,
      surface: card,
      onSurface: ink,
      error: Color(0xFFB3261E),
    ),
    scaffoldBackgroundColor: paper,
    fontFamily: 'Roboto',
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE0DED5)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
  );
}
