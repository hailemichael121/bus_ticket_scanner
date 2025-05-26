import 'package:flutter/material.dart';

class AppTheme {
  static const Color brightLime = Color(0xFFECF132);
  static const Color almostBlack = Color(0xFF1C1C1C);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFFC0C0C0);
  static const Color limeGreen = Color(0xFFECF132);
  static const Color subtitleGray = Color(0xFF888888);
  static const Color iconGray = Color(0xFFA3A3B3);
  static const Color softShadow = Color.fromRGBO(0, 0, 0, 0.1);
  static const Color errorRed = Color(0xFFFF0000);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: brightLime,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: almostBlack),
        titleTextStyle: const TextStyle(
          color: almostBlack,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: almostBlack,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        headlineMedium: TextStyle(
          color: almostBlack,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        bodyLarge: TextStyle(
          color: almostBlack,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: subtitleGray,
          fontSize: 14,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.brightLime,
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(color: AppTheme.almostBlack),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shadowColor: softShadow,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        buttonColor: limeGreen, // This is correct for ButtonThemeData
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: limeGreen,
          foregroundColor: almostBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: mediumGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: mediumGray),
        ),
        labelStyle: const TextStyle(color: subtitleGray),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: almostBlack,
        unselectedLabelColor: subtitleGray,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: limeGreen, width: 2),
        ),
      ),
    );
  }
}
