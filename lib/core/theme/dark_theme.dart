import 'package:flutter/material.dart';

class DarkTheme {
  static const accent = Color(0xFFFF6B2B);
  static const bg = Color(0xFF0D0D0F);
  static const card = Color(0xFF131316);

  static final theme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: bg,
    primaryColor: accent,
    colorScheme: const ColorScheme.dark(
      primary: accent,
    ),
    cardColor: card,
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
  );
}