import 'package:flutter/material.dart';

class AppTheme {
  // Primary color used throughout the app
  static const Color primaryColor = Color(0xFF1F4A7F); // Black
  
  // Secondary color for accents
  static const Color accentColor = Color(0xFF303030); // Dark gray
  
  // Background color for cards and dialogs
  static const Color backgroundColor = Color(0xFFFAFAFA);
  
  // Text colors
  static const Color textPrimaryColor = Color(0xFF303030);
  static const Color textSecondaryColor = Color(0xFF757575);
  
  // Button colors
  static const Color buttonColor = Color(0xFF1F4A7F);
  static const Color buttonTextColor = Color(0xFFFFFFFF);
  
  // Input field styling
  static InputDecoration inputDecoration(String hintText, {IconData? prefixIcon}) {
    return InputDecoration(
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      filled: true,
      fillColor: Colors.white.withOpacity(0.8),
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 15,
      ),
    );
  }
  
  // Button styling
  static ButtonStyle elevatedButtonStyle() {
    return ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      backgroundColor: buttonColor,
      foregroundColor: buttonTextColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
  
  // Text styling
  static TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );
  
  static TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );
  
  static TextStyle bodyTextStyle = TextStyle(
    fontSize: 16,
    color: textSecondaryColor,
  );
  
  // ThemeData for the entire app
  static ThemeData themeData = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: elevatedButtonStyle(),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
  );
}
