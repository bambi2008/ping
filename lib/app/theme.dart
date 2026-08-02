import 'package:flutter/material.dart';

class PingTheme {
  // ── Brand Colors ──
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFFA29BFE);
  static const Color secondary = Color(0xFF00D2D3);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFECA57);
  static const Color success = Color(0xFF2ED573);

  // ── Dark Palette ──
  static const Color darkBg = Color(0xFF0F0F1A);
  static const Color darkCard = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF252540);

  // ── Design Tokens ──
  // Radius scale: sm=10, md=14, lg=20, pill=full
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  // Spacing scale: 4,8,12,16,20,24,32,40
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double space2Xl = 24;
  static const double space3Xl = 32;
  static const double space4Xl = 40;

  // Typography scale
  static const double textCaption = 11;
  static const double textSmall = 13;
  static const double textBody = 15;
  static const double textTitle = 17;
  static const double textHeadline = 22;
  static const double textDisplay = 32;
  static const double textHero = 42;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: primary,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1A1A2E),
          titleTextStyle: TextStyle(
            fontSize: textHeadline,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd)),
          color: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF1F2F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: textBody, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: textSmall, fontWeight: FontWeight.w400),
          titleLarge: TextStyle(fontSize: textTitle, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontSize: textBody, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(fontSize: textHeadline, fontWeight: FontWeight.w800),
          labelLarge: TextStyle(fontSize: textBody, fontWeight: FontWeight.w600),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: primary,
        scaffoldBackgroundColor: darkBg,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: textHeadline,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd)),
          color: darkCard,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkSurface,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(radiusMd)),
            borderSide: BorderSide(color: primary.withValues(alpha: 0.6), width: 1.5),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: textBody, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: textSmall, fontWeight: FontWeight.w400),
          titleLarge: TextStyle(fontSize: textTitle, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontSize: textBody, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(fontSize: textHeadline, fontWeight: FontWeight.w800),
          labelLarge: TextStyle(fontSize: textBody, fontWeight: FontWeight.w600),
        ),
        dividerColor: darkSurface,
        listTileTheme: ListTileThemeData(
          iconColor: primary.withValues(alpha: 0.8),
        ),
      );

  // ── Semantic Helpers ──
  static Color subtleText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF8E8E9E)
          : const Color(0xFF7A7A8C);

  static Color cardSurface(BuildContext context) =>
      Theme.of(context).cardColor;

  static Color hairlineBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2A2A3E)
          : const Color(0xFFE8E8EE);
}
