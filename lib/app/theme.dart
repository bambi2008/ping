import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PingTheme {
  static const Color primary = Color(0xFF6C5CE7);
  static const Color secondary = Color(0xFF00D2D3);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFECA57);
  static const Color success = Color(0xFF2ED573);
  static const Color darkBg = Color(0xFF0F0F1A);
  static const Color darkCard = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF252540);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: primary,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1A1A2E),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: primary,
        scaffoldBackgroundColor: darkBg,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: darkCard,
        ),
      );
}
