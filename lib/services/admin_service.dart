import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Modelo simple para representar a un médico devuelto por la API
class DoctorUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? specialization;

  DoctorUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.specialization,
  });

  factory DoctorUser.fromJson(Map<String, dynamic> json) {
    return DoctorUser(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'MEDICO',
      specialization: json['specialization'] as String?,
    );
  }
}

/// Servicio para los endpoints de administración de médicos
/// Requiere JWT con rol ADMINISTRADOR
class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  String? get _token => html.window.localStorage['auth_token'];

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_token ?? ''}',
      };

  // ─────────────────────────────────────────────
  // POST /api/admin/doctors
  // ─────────────────────────────────────────────
  /// Crea un médico. Devuelve { success, doctor, tempPassword, message }
  Future<Map<String, dynamic>> createDoctor({
    required String name,
    String? specialization,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/admin/doctors');
      final body = <String, dynamic>{'name': name};
      if (specialization != null && specialization.isNotEmpty) {
        body['specialization'] = specialization;
      }

      final res = await http.post(
        uri,
        headers: _authHeaders,
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 201 || res.statusCode == 200) {
        final userJson = data['user'] as Map<String, dynamic>? ?? {};
        return {
          'success': true,
          'doctor': DoctorUser.fromJson(userJson),
          'tempPassword': data['tempPassword'] as String? ?? '',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error al crear el médico',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  // ─────────────────────────────────────────────
  // GET /api/admin/doctors
  // ─────────────────────────────────────────────
  /// Lista todos los médicos. Devuelve { success, doctors, message }
  Future<Map<String, dynamic>> listDoctors() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/admin/doctors');
      final res = await http.get(uri, headers: _authHeaders);
      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final list = (data is List ? data : data['doctors']) as List<dynamic>;
        final doctors = list
            .map((e) => DoctorUser.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'doctors': doctors};
      } else {
        final msg = (data is Map ? data['message'] : null) ?? 'Error al obtener médicos';
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }

  // ─────────────────────────────────────────────
  // DELETE /api/admin/doctors/:id
  // ─────────────────────────────────────────────
  /// Elimina un médico por ID. Devuelve { success, message }
  Future<Map<String, dynamic>> deleteDoctor(String id) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/admin/doctors/$id');
      final res = await http.delete(uri, headers: _authHeaders);

      if (res.statusCode == 200 || res.statusCode == 204) {
        return {'success': true};
      } else {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'success': false,
          'message': data['message'] ?? 'Error al eliminar el médico',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }
}
