import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/api_config.dart';
import '../models/analysis.dart';
import 'auth_service.dart';

class AnalysisService {
  static final AnalysisService _instance = AnalysisService._internal();
  factory AnalysisService() => _instance;
  AnalysisService._internal();

  /// POST /analyses — crear análisis, retorna 202 con status PENDING
  Future<Analysis> createAnalysis(String patientId, {XFile? imageFile, String? eye}) async {
    final authService = AuthService();
    final token = authService.currentUser?.token ?? '';

    var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/analyses'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['patientId'] = patientId;
    if (eye != null) {
      request.fields['eye'] = eye;
    }

    if (imageFile != null) {
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          await imageFile.readAsBytes(),
          filename: imageFile.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }
    }

    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    if (res.statusCode == 202 || res.statusCode == 201 || res.statusCode == 200) {
      // The API returns { message: '...', analysis: { ... } }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = body['analysis'] ?? body;
      return Analysis.fromJson(data as Map<String, dynamic>);
    }
    throw _apiError(res);
  }

  /// GET /analyses/:id — obtener análisis (usar para polling)
  Future<Analysis> getAnalysis(String id) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final res = await ApiConfig.get('/analyses/$id?_t=$timestamp');
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = body['analysis'] ?? body;
      return Analysis.fromJson(data as Map<String, dynamic>);
    }
    throw _apiError(res);
  }

  /// GET /analyses/patient/:patientId — análisis de un paciente
  Future<List<Analysis>> getAnalysesByPatient(String patientId) async {
    final res = await ApiConfig.get('/analyses/patient/$patientId');
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final List<dynamic> list = body is Map ? (body['analyses'] ?? []) : body;
      return list.map((e) => Analysis.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw _apiError(res);
  }

  /// GET /analyses/:id/logs — logs de procesamiento IA
  Future<List<String>> getLogs(String analysisId) async {
    final res = await ApiConfig.get('/analyses/$analysisId/logs');
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body is List) {
        return body.map((e) => e.toString()).toList();
      }
      return [];
    }
    throw _apiError(res);
  }

  /// DELETE /analyses/:id
  Future<void> deleteAnalysis(String id) async {
    final res = await ApiConfig.delete('/analyses/$id');
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw _apiError(res);
    }
  }

  /// Polling cada 2.5s hasta COMPLETED o FAILED.
  /// Emite actualizaciones via Stream.
  Stream<Analysis> pollUntilComplete(String analysisId) async* {
    while (true) {
      final analysis = await getAnalysis(analysisId);
      yield analysis;
      if (analysis.isFinished) break;
      await Future.delayed(const Duration(milliseconds: 2500));
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

  /// Actualiza las notas médicas de un análisis
  Future<Analysis> updateAnalysisNotes(String analysisId, String notes) async {
    final response = await ApiConfig.put('/analyses/$analysisId/notes', body: {'notes': notes});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Analysis.fromJson(data['analysis']);
    } else {
      throw _apiError(response);
    }
  }
}
