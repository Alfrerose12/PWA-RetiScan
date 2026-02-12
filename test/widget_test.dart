// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retiscan/main.dart';

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp()); // QUITÉ 'const' de aquí

    // Verify that the login screen is displayed
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Inicia sesión en tu cuenta'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
  });

  testWidgets('Login form validation works', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp()); // QUITÉ 'const' de aquí

    // Try to login without entering any data
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pump();

    // Should show validation errors
    expect(find.text('Por favor ingresa tu correo'), findsOneWidget);
    expect(find.text('Por favor ingresa tu contraseña'), findsOneWidget);
  });

  testWidgets('Navigate to register screen', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp()); // QUITÉ 'const' de aquí

    // Tap on register link
    await tester.tap(find.text('Regístrate'));
    await tester.pumpAndSettle();

    // Verify register screen is displayed
    expect(find.text('Crear Cuenta'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(5)); // All register fields
  });
}