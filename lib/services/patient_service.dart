import 'dart:async';
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

  String? get _token => _auth.currentUser?.token;

  Map<String, String> get _headers {
    final t = _token;
    if (t == null) throw Exception('No autenticado');
    return ApiConfig.authHeaders(t);
  }

  /// GET /patients — listar todos los pacientes
  Future<List<Patient>> getPatients() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/patients'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      // Handle both plain array and wrapped object {"patients":[...]/"data":[...]}
      List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map) {
        list = (decoded['patients'] ??
                decoded['data'] ??
                decoded['items'] ??
                []) as List<dynamic>;
      } else {
        list = [];
      }
      return list
          .map((e) => Patient.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw _apiError(res);
  }

  /// Extrae un Patient del body, manejando respuesta directa o envuelta.
  /// Ej: {...} o {"patient":{...}} o {"data":{...}}
  Patient _parsePatient(String body) {
    final decoded = jsonDecode(body);
    debugPrint('[PatientService] raw response: $body');
    Map<String, dynamic> map;
    if (decoded is Map<String, dynamic>) {
      // Si contiene la clave 'patient' o 'data', usar esa
      if (decoded.containsKey('patient') &&
          decoded['patient'] is Map<String, dynamic>) {
        map = decoded['patient'] as Map<String, dynamic>;
      } else if (decoded.containsKey('data') &&
          decoded['data'] is Map<String, dynamic>) {
        map = decoded['data'] as Map<String, dynamic>;
      } else {
        map = decoded;
      }
    } else {
      throw Exception('Respuesta inesperada del servidor');
    }
    return Patient.fromJson(map);
  }

  /// GET /patients/:id
  Future<Patient> getPatient(String id) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/patients/$id'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      return _parsePatient(res.body);
    }
    throw _apiError(res);
  }

  /// POST /patients — crear paciente (solo MEDICO)
  Future<Patient> createPatient({
    required String fullName,
    required int age,
    String? phone,
  }) async {
    // Enviar camelCase y snake_case para compatibilidad
    final body = <String, dynamic>{
      'fullName': fullName,
      'full_name': fullName,
      'age': age,
    };
    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
    }

    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/patients'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return _parsePatient(res.body);
    }
    throw _apiError(res);
  }

  /// PUT /patients/:id — actualizar paciente (parcial)
  Future<Patient> updatePatient(String id, Map<String, dynamic> data) async {
    // Asegurar que se envíe también snake_case
    final body = <String, dynamic>{};
    data.forEach((k, v) {
      body[k] = v;
      if (k == 'fullName') body['full_name'] = v;
      if (k == 'full_name') body['fullName'] = v;
    });

    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/patients/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      return _parsePatient(res.body);
    }
    throw _apiError(res);
  }

  /// DELETE /patients/:id — eliminar paciente (en cascada analyses)
  Future<void> deletePatient(String id) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/patients/$id'),
      headers: _headers,
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw _apiError(res);
    }
  }

  Exception _apiError(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return Exception(body['message'] ?? 'Error ${res.statusCode}');
    } catch (_) {
      return Exception('Error ${res.statusCode}');
    }
  }
}
