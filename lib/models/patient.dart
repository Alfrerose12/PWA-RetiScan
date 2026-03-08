import 'package:flutter/foundation.dart';

class Patient {
  final String id;
  final String firstName;
  final String paternalSurname;
  final String? maternalSurname;
  final DateTime? birthDate;
  final String? gender;   // 'MASCULINO' | 'FEMENINO' | 'OTRO'
  final String? email;
  final String? phone;
  final String? doctorId;
  final String? userId;
  final int totalAnalyses;
  final DateTime? createdAt;

  Patient({
    required this.id,
    required this.firstName,
    required this.paternalSurname,
    this.maternalSurname,
    this.birthDate,
    this.gender,
    this.email,
    this.phone,
    this.doctorId,
    this.userId,
    this.totalAnalyses = 0,
    this.createdAt,
  });

  /// Nombre completo para mostrar en la UI
  String get fullName {
    final parts = [firstName, paternalSurname, maternalSurname]
        .where((p) => p != null && p.isNotEmpty)
        .join(' ');
    return parts;
  }

  /// Alias para compatibilidad con pantallas existentes
  int get age {
    if (birthDate == null) return 0;
    final now = DateTime.now();
    int years = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      years--;
    }
    return years;
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    try {
      DateTime? bd;
      final rawBd = json['birth_date'] ?? json['birthDate'];
      if (rawBd != null) bd = DateTime.tryParse(rawBd.toString());

      DateTime? ca;
      final rawCa = json['created_at'] ?? json['createdAt'];
      if (rawCa != null) ca = DateTime.tryParse(rawCa.toString());

      return Patient(
        id:              (json['id'] ?? '').toString(),
        firstName:       (json['first_name'] ?? json['firstName'] ?? '').toString(),
        paternalSurname: (json['paternal_surname'] ?? json['paternalSurname'] ?? '').toString(),
        maternalSurname: (json['maternal_surname'] ?? json['maternalSurname'])?.toString(),
        birthDate:       bd,
        gender:          json['gender']?.toString(),
        email:           json['email']?.toString(),
        phone:           json['phone']?.toString(),
        doctorId:        json['doctor_id']?.toString(),
        userId:          json['user_id']?.toString(),
        totalAnalyses:   ((json['total_analyses'] ?? json['totalAnalyses']) as num?)?.toInt() ?? 0,
        createdAt:       ca,
      );
    } catch (e) {
      debugPrint('[Patient.fromJson] ERROR: $e\nJSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'id':              id,
    'firstName':       firstName,
    'paternalSurname': paternalSurname,
    if (maternalSurname != null) 'maternalSurname': maternalSurname,
    if (birthDate != null) 'birthDate': birthDate!.toIso8601String().split('T').first,
    if (gender != null) 'gender': gender,
    if (email  != null) 'email':  email,
    if (phone  != null) 'phone':  phone,
  };

  Patient copyWith({
    String?   id,
    String?   firstName,
    String?   paternalSurname,
    String?   maternalSurname,
    DateTime? birthDate,
    String?   gender,
    String?   email,
    String?   phone,
    String?   doctorId,
    String?   userId,
    int?      totalAnalyses,
    DateTime? createdAt,
  }) {
    return Patient(
      id:              id              ?? this.id,
      firstName:       firstName       ?? this.firstName,
      paternalSurname: paternalSurname ?? this.paternalSurname,
      maternalSurname: maternalSurname ?? this.maternalSurname,
      birthDate:       birthDate       ?? this.birthDate,
      gender:          gender          ?? this.gender,
      email:           email           ?? this.email,
      phone:           phone           ?? this.phone,
      doctorId:        doctorId        ?? this.doctorId,
      userId:          userId          ?? this.userId,
      totalAnalyses:   totalAnalyses   ?? this.totalAnalyses,
      createdAt:       createdAt       ?? this.createdAt,
    );
  }
}
