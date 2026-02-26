import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isDoctor => _currentUser?.isDoctor ?? false;
  bool get isClient => _currentUser?.isClient ?? true;

  /// Token guardado en localStorage (persiste al recargar, se borra al cerrar sesión)
  String? get _token => html.window.localStorage['auth_token'];

  void _saveToken(String token) {
    html.window.localStorage['auth_token'] = token;
  }

  /// Intenta restaurar sesión desde localStorage al arrancar la app
  Future<bool> loadUserFromSession() async {
    final token = _token;
    if (token == null) return false;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/users/profile');
      final res = await http.get(uri, headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _currentUser = User.fromJson(data).copyWith(token: token);
        return true;
      } else {
        // Token expirado o inválido — limpiar
        html.window.localStorage.remove('auth_token');
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  /// Login → POST /users/login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/users/login');
      final res = await http.post(
        uri,
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        final token = body['token'] as String;
        final userData = body['user'] as Map<String, dynamic>;
        _currentUser = User.fromJson(userData).copyWith(token: token);
        _saveToken(token);
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Credenciales inválidas',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  /// Solicitar código 2FA → POST /auth/2fa/send
  /// Retorna el código generado (visible en desarrollo) o null si falla.
  Future<String?> request2FA() async {
    final token = _token;
    if (token == null) return null;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/2fa/send');
      final res = await http.post(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['code']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Verificar código 2FA → POST /auth/2fa/verify
  Future<bool> verify2FA(String code) async {
    final token = _token;
    if (token == null) return false;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/2fa/verify');
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'code': code}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Register → POST /users/register
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/users/register');
      final res = await http.post(
        uri,
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 201 || res.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Error al registrar usuario',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  /// Actualizar perfil → PUT /users/profile
  Future<Map<String, dynamic>> updateProfile({
    String? email,
    String? password,
  }) async {
    final token = _token;
    if (token == null) return {'success': false, 'message': 'No autenticado'};

    final body = <String, dynamic>{};
    if (email != null) body['email'] = email;
    if (password != null) body['password'] = password;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/users/profile');
      final res = await http.put(
        uri,
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _currentUser = User.fromJson(data).copyWith(token: token);
        return {'success': true};
      } else {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {'success': false, 'message': data['message'] ?? 'Error al actualizar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  /// Cerrar sesión — limpia localStorage y memoria
  Future<void> logout() async {
    html.window.localStorage.remove('auth_token');
    _currentUser = null;
  }

  /// Limpiar toda la sesión (usado desde modo desarrollador)
  Future<void> clearStorage() async {
    html.window.localStorage.clear();
    _currentUser = null;
  }

  /// Cambiar rol en memoria — solo modo desarrollador
  Future<void> switchRole(String newRole) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(role: newRole);
    }
  }

  /// ¿El usuario puede ver opciones de desarrollador?
  bool get isDeveloper =>
      _currentUser?.email.endsWith('@yada.com') ?? false;
}
