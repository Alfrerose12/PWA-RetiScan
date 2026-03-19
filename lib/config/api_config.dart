// Configuración global de la API RetiScan
// La URL base se deriva automáticamente del host desde el que se sirve la app,
// por lo que funciona con cualquier IP sin necesidad de recompilar.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import '../services/auth_service.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ApiConfig {
  /// Puerto donde corre el backend Node/Express.
  static const int _apiPort = 3000;

  static String get baseUrl {
    final host = html.window.location.hostname ?? 'localhost';
    return 'http://$host:$_apiPort/api';
  }

  // Headers para requests autenticados (usado internamente o legacy)
  static Map<String, String> authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // Headers para requests públicos
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
  };

  // ─────────────────────────────────────────────────────────────────
  // CLIENTE HTTP GLOBAL W/ CREDENTIALS & AUTO-REFRESH (Interceptor)
  // ─────────────────────────────────────────────────────────────────
  static http.Client get _baseClient => BrowserClient()..withCredentials = true;

  static Future<http.Response> request(
    String method,
    String endpoint, {
    dynamic body, // Puede ser Map<String, dynamic> o String encodado
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse(baseUrl + endpoint);
    var token = AuthService().token;
    var headers = (requiresAuth && token != null) ? authHeaders(token) : jsonHeaders;

    http.Response response = await _sendRequest(method, uri, headers, body);

    // Interceptor: Si expira el token, intenta Refresh
    if (response.statusCode == 401 && requiresAuth) {
      final authOk = await AuthService().doRefresh();
      if (authOk) {
        token = AuthService().token;
        headers = authHeaders(token!);
        response = await _sendRequest(method, uri, headers, body);
      } else {
        AuthService().clearStorage();
      }
    }
    return response;
  }

  static Future<http.Response> _sendRequest(String m, Uri u, Map<String, String> h, dynamic b) async {
    final client = _baseClient;
    final encoded = b is Map ? jsonEncode(b) : b; // codifica si es mapa, literal si es string
    switch (m) {
      case 'POST':   return client.post(u, headers: h, body: encoded);
      case 'PUT':    return client.put(u, headers: h, body: encoded);
      case 'PATCH':  return client.patch(u, headers: h, body: encoded);
      case 'DELETE': return client.delete(u, headers: h, body: encoded);
      case 'GET':
      default:       return client.get(u, headers: h);
    }
  }

  // Wrappers directos
  static Future<http.Response> get(String endpoint) => request('GET', endpoint);
  static Future<http.Response> post(String endpoint, {dynamic body}) => request('POST', endpoint, body: body);
  static Future<http.Response> put(String endpoint, {dynamic body})  => request('PUT', endpoint, body: body);
  static Future<http.Response> patch(String endpoint, {dynamic body}) => request('PATCH', endpoint, body: body);
  static Future<http.Response> delete(String endpoint, {dynamic body}) => request('DELETE', endpoint, body: body);
}

