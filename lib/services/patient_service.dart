import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/patient.dart';
import 'auth_service.dart';

class PatientService {
  static final PatientService _instance = PatientService._internal();
  factory PatientService() => _instance;
  PatientService._internal();

  final AuthService _auth = AuthService();

  Map<String, String> get _headers {
    final t = _auth.token;
    if (t == null) throw Exception('No autenticado');
    return ApiConfig.authHeaders(t);
  }

  // ─────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────
  Patient _parsePatient(String body) {
    final decoded = jsonDecode(body);
    debugPrint('[PatientService] raw: $body');
    Map<String, dynamic> map;
    if (decoded is Map<String, dynamic>) {
      map = (decoded['patient'] ?? decoded['data'] ?? decoded)
          as Map<String, dynamic>;
    } else {
      throw Exception('Respuesta inesperada del servidor');
    }
    return Patient.fromJson(map);
  }

  Exception _apiError(http.Response res) {
    try {
      final b = jsonDecode(res.body) as Map<String, dynamic>;
      return Exception(b['error'] ?? b['message'] ?? 'Error ${res.statusCode}');
    } catch (_) {
      return Exception('Error ${res.statusCode}');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // MEDICO: Listar pacientes → GET /patients
  // ─────────────────────────────────────────────────────────────────
  Future<List<Patient>> getPatients() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/patients'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map) {
        list = (decoded['patients'] ?? decoded['data'] ?? []) as List<dynamic>;
      } else {
        list = [];
      }
      return list
          .map((e) => Patient.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw _apiError(res);
  }

  // ─────────────────────────────────────────────────────────────────
  // MEDICO: Obtener paciente → GET /patients/:id
  // ─────────────────────────────────────────────────────────────────
  Future<Patient> getPatient(String id) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/patients/$id'),
      headers: _headers,
    );
    if (res.statusCode == 200) return _parsePatient(res.body);
    throw _apiError(res);
  }

  // ─────────────────────────────────────────────────────────────────
  // MEDICO: Crear paciente → POST /patients
  // Solo requiere firstName, paternalSurname, maternalSurname
  // Devuelve también las credenciales generadas
  // ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createPatient({
    required String firstName,
    required String paternalSurname,
    String? maternalSurname,
  }) async {
    final body = <String, dynamic>{
      'firstName':       firstName,
      'paternalSurname': paternalSurname,
      if (maternalSurname != null && maternalSurname.isNotEmpty)
        'maternalSurname': maternalSurname,
    };

    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/patients'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final patient     = Patient.fromJson(decoded['patient'] as Map<String, dynamic>);
      final credentials = decoded['credentials'] as Map<String, dynamic>? ?? {};
      return {
        'patient':      patient,
        'username':     credentials['username'] ?? '',
        'tempPassword': credentials['tempPassword'] ?? '',
        'note':         credentials['note'] ?? '',
      };
    }
    throw _apiError(res);
  }

  // ─────────────────────────────────────────────────────────────────
  // MEDICO: Actualizar paciente → PUT /patients/:id
  // ─────────────────────────────────────────────────────────────────
  Future<Patient> updatePatient(String id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/patients/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return _parsePatient(res.body);
    throw _apiError(res);
  }

  // ─────────────────────────────────────────────────────────────────
  // MEDICO: Eliminar paciente → DELETE /patients/:id
  // ─────────────────────────────────────────────────────────────────
  Future<void> deletePatient(String id) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/patients/$id'),
      headers: _headers,
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw _apiError(res);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // PACIENTE: Ver mi expediente → GET /patients/me
  // ─────────────────────────────────────────────────────────────────
  Future<Patient> getMyRecord() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/patients/me'),
      headers: _headers,
    );
    if (res.statusCode == 200) return _parsePatient(res.body);
    throw _apiError(res);
  }

  // ─────────────────────────────────────────────────────────────────
  // PACIENTE: Completar perfil (primer login) → PATCH /patients/me
  // Campos: birthDate, gender, email, phone
  // ─────────────────────────────────────────────────────────────────
  Future<Patient> updateMyProfile({
    DateTime? birthDate,
    String?   gender,
    String?   email,
    String?   phone,
  }) async {
    final body = <String, dynamic>{};
    if (birthDate != null) body['birthDate'] = birthDate.toIso8601String().split('T').first;
    if (gender    != null) body['gender']    = gender;
    if (email     != null) body['email']     = email;
    if (phone     != null) body['phone']     = phone;

    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/patients/me'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) return _parsePatient(res.body);
    throw _apiError(res);
  }
}
