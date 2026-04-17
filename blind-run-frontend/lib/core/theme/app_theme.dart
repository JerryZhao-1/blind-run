import 'package:flutter/material.dart';

class AppTheme {
  static const yellow = Color(0xFFFACC15);
  static const black = Color(0xFF09090B);
  static const zinc = Color(0xFF18181B);
  static const emerald = Color(0xFF10B981);
  static const softGray = Color(0xFFF5F5F5);
  static const red = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.black,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'SF Pro Display'),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: black,
      colorScheme: ColorScheme.fromSeed(
        seedColor: yellow,
        brightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'SF Pro Display'),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
