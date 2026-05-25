
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.indigo,
    scaffoldBackgroundColor: Color(0xFF121212),
  );

  static ThemeData get neonTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Color(0xFF000000),
    primaryColor: Colors.cyanAccent,
    // Add Neon specific glow effects here
  );
}
