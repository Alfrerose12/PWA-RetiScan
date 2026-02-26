import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  bool _isDarkMode = false;
  static const String _themeKey = 'isDarkMode';

  bool get isDarkMode => _isDarkMode;

  ThemeService() {
    loadTheme();
  }

  // Tema Claro - Diseño Original
  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: Color(0xFF2563EB),        // Azul Rey (Primary Brand)
          secondary: Color(0xFF2563EB),      // Azul Oscuro (Gradiente Hero)
          surface: Color(0xFFFFFFFF),        // Background Light
          background: Color(0xFFFFFFFF),     // Background Light
          onPrimary: Color(0xFFFFFFFF),      // Primary Light
          onSecondary: Color(0xFFFFFFFF),    // Primary Light
          onSurface: Color(0xFF252525),      // Foreground Light
          onBackground: Color(0xFF252525),   // Foreground Light
          error: Color(0xFFd4183d),          // Destructive
        ),
        primaryColor: Color(0xFF2563EB),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2B2C2E),
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2B2C2E),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF2B2C2E),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF2B2C2E),
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: Color(0xFF2B2C2E).withOpacity(0.7),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2B2C2E),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF2D385E)),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFf97316),  // Naranja (Botón de Acción)
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),  // Border Radius Base
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          floatingLabelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          hintStyle: TextStyle(
            fontSize: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Color(0xFF2563EB),
              width: 2,
            ),
          ),
        ),
      );

  // Tema Oscuro - Adaptado del diseño original
  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF60A5FA),        // Azul Claro (Primary en oscuro)
          secondary: Color(0xFF0EA5E9),      // Azul Claro (Gradiente Hero)
          surface: Color(0xFF1f1f1f),        // Sidebar Background
          background: Color(0xFF1a1a1a),     // Background Dark
          onPrimary: Color(0xFF030213),      // Primary Dark
          onSecondary: Color(0xFF030213),    // Primary Dark
          onSurface: Color(0xFFfafafa),      // Foreground Dark
          onBackground: Color(0xFFfafafa),   // Foreground Dark
          error: Color(0xFFd4183d),          // Destructive
        ),
        primaryColor: Color(0xFF60A5FA),
        scaffoldBackgroundColor: Color(0xFF1a1a1a),
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1f1f1f),
          foregroundColor: Color(0xFFfafafa),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF0EA5E9)),
        ),
        cardTheme: CardThemeData(
          color: Color(0xFF1f1f1f),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFf97316),  // Naranja (Botón de Acción)
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),  // Border Radius Base
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          floatingLabelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          hintStyle: TextStyle(
            fontSize: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Color(0xFF64C8FF),
              width: 2,
            ),
          ),
        ),
      );

  // Cargar tema guardado
  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  // Cambiar tema
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  // Establecer tema específico
  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_themeKey, _isDarkMode);
      } catch (e) {
        print('Error saving theme: $e');
      }
    }
  }
}
