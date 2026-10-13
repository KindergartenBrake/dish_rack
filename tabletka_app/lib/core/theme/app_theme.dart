import 'package:flutter/material.dart';

/// Тема приложения «Таблеточница».
///
/// Цвета и размеры подобраны под макет: крупные шрифты,
/// контрастные статусы, мягкий серый фон.
class AppTheme {
  AppTheme._();

  // ─── Цвета ───────────────────────────────────────────────
  static const Color background = Color(0xFFF5F5F7);
  static const Color cardWhite = Colors.white;

  static const Color accentBlue = Color(0xFF3B82F6);

  static const Color statusTaken = Color(0xFF10B981);   // зелёный
  static const Color statusPending = Color(0xFF9CA3AF); // серый
  static const Color statusSkipped = Color(0xFFEF4444); // красный
  static const Color statusPostponed = Color(0xFFF59E0B); // оранжевый

  // ─── Тема ────────────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentBlue,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineMedium: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyLarge: const TextStyle(
          fontSize: 18,
          color: Colors.black87,
        ),
        bodyMedium: const TextStyle(
          fontSize: 16,
          color: Colors.black54,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        foregroundColor: Colors.black87,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}