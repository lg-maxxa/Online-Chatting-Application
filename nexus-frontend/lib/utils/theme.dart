import 'package:flutter/material.dart';

/// NexusChat design system – colors, typography, and ThemeData.
class AppTheme {
  AppTheme._();

  // ── Brand Colors (WhatsApp-inspired green palette) ─────────────────────────
  static const Color primaryGreen = Color(0xFF075E54);
  static const Color lightGreen = Color(0xFF25D366);
  static const Color tealGreen = Color(0xFF128C7E);
  static const Color chatBackground = Color(0xFFECE5DD);

  // ── Neutral Colors ─────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF0F0F0);
  static const Color lightGrey = Color(0xFFD1D7DB);
  static const Color mediumGrey = Color(0xFF8696A0);
  static const Color darkGrey = Color(0xFF3B4A54);
  static const Color black = Color(0xFF111B21);

  // ── Message Bubble Colors ──────────────────────────────────────────────────
  static const Color sentBubble = Color(0xFFD9FDD3);
  static const Color receivedBubble = Color(0xFFFFFFFF);

  // ── Typography ─────────────────────────────────────────────────────────────
  static const TextStyle headingLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: white,
    letterSpacing: -0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    color: black,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: mediumGrey,
  );

  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          secondary: lightGreen,
          surface: white,
          background: offWhite,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryGreen,
          foregroundColor: white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: headingLarge,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: lightGreen,
          foregroundColor: white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: offWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: tealGreen, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: tealGreen,
            foregroundColor: white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          brightness: Brightness.dark,
          primary: lightGreen,
          secondary: tealGreen,
          surface: const Color(0xFF1F2C34),
          background: const Color(0xFF0B141A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F2C34),
          foregroundColor: white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: lightGreen,
          foregroundColor: white,
        ),
      );
}
