import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  
  // ─────────────────────────────────────────────────────────────────
  // Autenticación Avanzada (JWT Access Token en RAM)
  // ─────────────────────────────────────────────────────────────────
  String? _accessToken; // El token ahora vive solo en memoria, NO en localStorage

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isDoctor  => _currentUser?.isDoctor  ?? false;
  bool get isPatient => _currentUser?.isPatient ?? false;
  bool get isAdmin   => _currentUser?.isAdmin   ?? false;
  bool get isClient => isPatient;

  String? get token => _accessToken;

  // Generamos un cliente HTTP que soporte cookies cross-origin (withCredentials)
  // crucial para que navegue el Refresh Token HttpOnly entre nuestra PWA y la API.
  http.Client get _client {
    var client = BrowserClient()..withCredentials = true;
    return client;
  }

  // ─────────────────────────────────────────────────────────────────
  // Restaurar sesión al arrancar la app usando Refresh Token Cookie
  // ─────────────────────────────────────────────────────────────────
  Future<bool> loadUserFromSession() async {
    // 1. Intentamos obtener un nuevo Access Token usando el Refresh Token (Cookie)
    final refreshOk = await doRefresh();
    if (!refreshOk) return false;

    // 2. Si el refresh nos dio un token de 15m, bajamos el perfil
    final t = _accessToken;
    if (t == null) return false;
    
    try {
      final res = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/users/profile'),
        headers: ApiConfig.authHeaders(t),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final userData = (data['user'] ?? data) as Map<String, dynamic>;
        _currentUser = User.fromJson(userData).copyWith(token: t);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ─────────────────────────────────────────────────────────────────
  // Lógica de Renovación Secreta de Sesión (/api/auth/refresh)
  // ─────────────────────────────────────────────────────────────────
  Future<bool> doRefresh() async {
    try {
      final res = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
        headers: ApiConfig.jsonHeaders,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _accessToken = data['token'] as String; // Guardar nuevo token en RAM
        return true;
      }
      return false; // Token expirado de verdad o no existente
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Login → POST /auth/login
  // ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final res = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({'identifier': identifier, 'password': password}),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        final t        = body['token'] as String;
        final userData = body['user'] as Map<String, dynamic>;
        _accessToken   = t; // Solo a memoria
        _currentUser   = User.fromJson(userData).copyWith(token: t);

        return {
          'success':            true,
          'mustChangePassword': _currentUser!.mustChangePassword,
          'isVerified':         _currentUser!.isVerified,
          'role':               _currentUser!.role,
        };
      } else if (res.statusCode == 206) {
        return {
          'success': true,
          'requires2FA': true,
          'userId': body['userId'],
          'message': body['message'] ?? 'Código OTP enviado',
        };
      } else {
        // 401, 403, etc.
        final msg = (body['error'] ?? body['message'] ?? 'Credenciales inválidas').toString();
        return {'success': false, 'message': msg, 'statusCode': res.statusCode};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Verificar OTP del Login (MFA Paso 2) → POST /auth/verify-login-otp
  // ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> verifyLoginOtp(String userId, String otp) async {
    try {
      final res = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify-login-otp'),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode({'userId': userId, 'otp': otp}),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        final t        = body['token'] as String;
        final userData = body['user'] as Map<String, dynamic>;
        _accessToken   = t; // Guardar a RAM final
        _currentUser   = User.fromJson(userData).copyWith(token: t);

        return {
          'success':            true,
          'mustChangePassword': _currentUser!.mustChangePassword,
          'isVerified':         _currentUser!.isVerified,
          'role':               _currentUser!.role,
        };
      } else {
        final msg = (body['error'] ?? body['message'] ?? 'Código OTP inválido').toString();
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Cambiar contraseña → PUT /users/change-password
  // ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> changePassword(String newPassword, [String? otp]) async {
    final t = _accessToken;
    if (t == null) return {'success': false, 'message': 'No autenticado'};
    try {
      final bodyData = <String, dynamic>{'newPassword': newPassword};
      if (otp != null && otp.isNotEmpty) {
        bodyData['otp'] = otp;
      }
      
      final res = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/users/change-password'),
        headers: ApiConfig.authHeaders(t),
        body: jsonEncode(bodyData),
      );
      if (res.statusCode == 200) {
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
    final t = _accessToken;
    final headers = t == null ? ApiConfig.jsonHeaders : ApiConfig.authHeaders(t);
    try {
      final res = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/send-otp'),
        headers: headers,
        body: jsonEncode({'email': email, 'type': type}),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {
          'success': true,
          'devOtp': body['_dev_otp']?.toString(),
        };
      }
      return {'success': false, 'message': body['error'] ?? 'Error al enviar OTP'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  // Métodos de compatibilidad para el nuevo flujo visual de registro (PWA)
  Future<String?> request2FAUnauth(String email) async {
    // Simulamos el envío llamando a sendOtp (que intenta usar el endpoint de siempre)
    final res = await sendOtp(email);
    if (res['success'] == true) {
      return res['devOtp']?.toString() ?? 'Enviado';
    }
    return null;
  }

  Future<bool> verify2FAUnauth(String email, String code) async {
    final res = await verifyOtp(code);
    return res['success'] == true;
  }

  // ─────────────────────────────────────────────────────────────────
  // Verificar OTP → POST /auth/verify-otp
  // ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> verifyOtp(String otp, {String type = 'OTP_EMAIL'}) async {
    final t = _accessToken;
    if (t == null) return {'success': false, 'message': 'No autenticado'};
    try {
      final res = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify-otp'),
        headers: ApiConfig.authHeaders(t),
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
    try {
      final t = _accessToken;
      if (t != null) {
        await _client.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
          headers: ApiConfig.authHeaders(t),
        );
      }
    } catch (_) {}

    _accessToken = null;
    _currentUser = null;
  }

  Future<void> clearStorage() async {
    _accessToken = null;
    _currentUser = null;
  }

  bool get isDeveloper =>
      _currentUser?.email?.endsWith('@yada.com') ?? false;
}
