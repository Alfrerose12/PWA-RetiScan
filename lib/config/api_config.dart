// Configuración global de la API RetiScan
// La URL base se deriva automáticamente del host desde el que se sirve la app,
// por lo que funciona con cualquier IP sin necesidad de recompilar.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ApiConfig {
  /// Puerto donde corre el backend Node/Express.
  static const int _apiPort = 3000;

  /// URL base de la API, construida dinámicamente a partir del host del navegador.
  /// Ejemplo: si accedes a http://192.168.1.50:5000, esta propiedad devuelve
  ///          http://192.168.1.50:3000/api
  static String get baseUrl {
    final host = html.window.location.hostname ?? 'localhost';
    return 'http://$host:$_apiPort/api';
  }

  // Headers para requests autenticados
  static Map<String, String> authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // Headers para requests públicos (login, register)
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
  };
}

