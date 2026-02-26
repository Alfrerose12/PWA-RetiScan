import 'package:flutter/foundation.dart';

class Patient {
  final String id;
  final String fullName;
  final int age;
  final String? phone;
  final DateTime? lastVisit;
  final int totalAnalyses;

  Patient({
    required this.id,
    required this.fullName,
    required this.age,
    this.phone,
    this.lastVisit,
    this.totalAnalyses = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'age': age,
      if (phone != null) 'phone': phone,
      if (lastVisit != null) 'lastVisit': lastVisit!.toIso8601String(),
      'totalAnalyses': totalAnalyses,
    };
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    // Support both snake_case (raw DB) and camelCase (remapped API)
    // Debug: descomentar si hay problemas → debugPrint('Patient JSON: $json');
    try {
      final rawLastVisit = json['last_visit'] ?? json['lastVisit'];
      return Patient(
        id: (json['id'] ?? '').toString(),
        fullName: ((json['full_name'] ?? json['fullName']) ?? '').toString(),
        age: ((json['age'] as num?) ?? 0).toInt(),
        phone: json['phone']?.toString(),
        lastVisit: rawLastVisit != null
            ? DateTime.tryParse(rawLastVisit.toString())
            : null,
        totalAnalyses:
            ((json['total_analyses'] ?? json['totalAnalyses']) as num?)
                ?.toInt() ??
                0,
      );
    } catch (e) {
      // Imprime el JSON completo para diagnóstico en consola de desarrollo
      debugPrint('[Patient.fromJson] ERROR: $e\nJSON recibido: $json');
      rethrow;
    }
  }

  Patient copyWith({
    String? id,
    String? fullName,
    int? age,
    String? phone,
    DateTime? lastVisit,
    int? totalAnalyses,
  }) {
    return Patient(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      lastVisit: lastVisit ?? this.lastVisit,
      totalAnalyses: totalAnalyses ?? this.totalAnalyses,
    );
  }
}
