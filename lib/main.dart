import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RetiScan',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Color(0xFF2D385E),      // Azul oscuro principal
          secondary: Color(0xFF5258A4),    // Azul violeta secundario
          surface: Colors.white,           // Fondo de superficies
          background: Color(0xFFFFFFFF),   // Fondo general
          onPrimary: Colors.white,         // Texto sobre primary
          onSecondary: Colors.white,       // Texto sobre secondary
          onSurface: Color(0xFF2B2C2E),    // Texto principal
          onBackground: Color(0xFF2B2C2E), // Texto sobre fondo
        ),
        primaryColor: Color(0xFF2D385E),
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
            backgroundColor: Color(0xFF2D385E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Color(0xFF5258A4),
              width: 2,
            ),
          ),
        ),
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}