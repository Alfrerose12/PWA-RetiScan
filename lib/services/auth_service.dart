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
  bool get isDoctor  => _currentUser?.isDoctor  ?? false;
  bool get isPatient => _currentUser?.isPatient ?? false;
  bool get isAdmin   => _currentUser?.isAdmin   ?? false;

  // Alias para compatibilidad con pantallas existentes
  bool get isClient => isPatient;

  String? get _token => html.window.localStorage['auth_token'];

  void _saveToken(String token) =>
      html.window.localStorage['auth_token'] = token;

  // ─────────────────────────────────────────────────────────────────
  // Restaurar sesión desde localStorage al arrancar la app
  // ─────────────────────────────────────────────────────────────────
  Future<bool> loadUserFromSession() async {
    final token = _token;
    if (token == null) return false;
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/profile'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        // La API devuelve { user: {...} } o directamente el objeto
        final userData = (data['user'] ?? data) as Map<String, dynamic>;
        _currentUser = User.fromJson(userData).copyWith(token: token);
        return true;
      } else {
        html.window.localStorage.remove('auth_token');
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Login → POST /auth/login
  // identifier puede ser email (médico) o username (paciente)
  // ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({'identifier': identifier, 'password': password}),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        final token    = body['token'] as String;
        final userData = body['user'] as Map<String, dynamic>;
        _currentUser   = User.fromJson(userData).copyWith(token: token);
        _saveToken(token);

        return {
          'success':            true,
          'mustChangePassword': _currentUser!.mustChangePassword,
          'isVerified':         _currentUser!.isVerified,
          'role':               _currentUser!.role,
        };
      } else {
        // 403 = cuenta no verificada
        final msg = (body['error'] ?? body['message'] ?? 'Credenciales inválidas').toString();
        return {'success': false, 'message': msg, 'statusCode': res.statusCode};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Cambiar contraseña → POST /users/change-password
  // ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> changePassword(String newPassword) async {
    final token = _token;
    if (token == null) return {'success': false, 'message': 'No autenticado'};
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/change-password'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'newPassword': newPassword}),
      );
      if (res.statusCode == 200) {
        // Actualizar flag en memoria
        _currentUser = _currentUser?.copyWith(mustChangePassword: false);
        return {'success': true};
      } else {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {'success': false, 'message': data['error'] ?? 'Error al cambiar contraseña'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Enviar OTP → POST /auth/send-otp
  // type: 'OTP_EMAIL' | 'OTP_SMS'
  // ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> sendOtp(String email, {String type = 'OTP_EMAIL'}) async {
    final token = _token;
    if (token == null) return {'success': false, 'message': 'No autenticado'};
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/send-otp'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'email': email, 'type': type}),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {
          'success': true,
          // En desarrollo la API devuelve el OTP directamente
          'devOtp': body['_dev_otp']?.toString(),
        };
      }
      return {'success': false, 'message': body['error'] ?? 'Error al enviar OTP'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Verificar OTP → POST /auth/verify-otp
  // ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> verifyOtp(String otp, {String type = 'OTP_EMAIL'}) async {
    final token = _token;
    if (token == null) return {'success': false, 'message': 'No autenticado'};
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify-otp'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'otp': otp, 'type': type}),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        _currentUser = _currentUser?.copyWith(isVerified: true);
        return {'success': true};
      }
      return {'success': false, 'message': body['error'] ?? 'Código OTP inválido o expirado'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Cerrar sesión
  // ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    html.window.localStorage.remove('auth_token');
    _currentUser = null;
  }

  Future<void> clearStorage() async {
    html.window.localStorage.clear();
    _currentUser = null;
  }

  /// Expone el token para que otros servicios puedan usarlo
  String? get token => _token;

  bool get isDeveloper =>
      _currentUser?.email?.endsWith('@yada.com') ?? false;
}
