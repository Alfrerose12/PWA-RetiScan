class Patient {
  final String id;
  final String fullName;
  final int age;
  final String email;
  final DateTime lastVisit;
  final int totalAnalyses;
  final String status;
  final String? profileImage;
  final String? phone;
  final String? notes;

  Patient({
    required this.id,
    required this.fullName,
    required this.age,
    required this.email,
    required this.lastVisit,
    required this.totalAnalyses,
    required this.status,
    this.profileImage,
    this.phone,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'age': age,
      'email': email,
      'lastVisit': lastVisit.toIso8601String(),
      'totalAnalyses': totalAnalyses,
      'status': status,
      'profileImage': profileImage,
      'phone': phone,
      'notes': notes,
    };
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      age: json['age'] as int,
      email: json['email'] as String,
      lastVisit: DateTime.parse(json['lastVisit'] as String),
      totalAnalyses: json['totalAnalyses'] as int,
      status: json['status'] as String,
      profileImage: json['profileImage'] as String?,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Patient copyWith({
    String? id,
    String? fullName,
    int? age,
    String? email,
    DateTime? lastVisit,
    int? totalAnalyses,
    String? status,
    String? profileImage,
    String? phone,
    String? notes,
  }) {
    return Patient(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      email: email ?? this.email,
      lastVisit: lastVisit ?? this.lastVisit,
      totalAnalyses: totalAnalyses ?? this.totalAnalyses,
      status: status ?? this.status,
      profileImage: profileImage ?? this.profileImage,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
    );
  }

  static List<Patient> getMockPatients() {
    return [
      Patient(
        id: 'p001',
        fullName: 'Juan Pérez',
        age: 45,
        email: 'juan.perez@email.com',
        lastVisit: DateTime.now().subtract(Duration(days: 15)),
        totalAnalyses: 12,
        status: 'Normal',
        phone: '+52 123 456 7890',
      ),
      Patient(
        id: 'p002',
        fullName: 'María López',
        age: 52,
        email: 'maria.lopez@email.com',
        lastVisit: DateTime.now().subtract(Duration(days: 7)),
        totalAnalyses: 8,
        status: 'Leve',
        phone: '+52 123 456 7891',
      ),
      Patient(
        id: 'p003',
        fullName: 'Carlos Ramírez',
        age: 38,
        email: 'carlos.ramirez@email.com',
        lastVisit: DateTime.now().subtract(Duration(days: 30)),
        totalAnalyses: 15,
        status: 'Normal',
        phone: '+52 123 456 7892',
      ),
      Patient(
        id: 'p004',
        fullName: 'Ana Martínez',
        age: 60,
        email: 'ana.martinez@email.com',
        lastVisit: DateTime.now().subtract(Duration(days: 3)),
        totalAnalyses: 20,
        status: 'Moderado',
        phone: '+52 123 456 7893',
      ),
      Patient(
        id: 'p005',
        fullName: 'Roberto Silva',
        age: 48,
        email: 'roberto.silva@email.com',
        lastVisit: DateTime.now().subtract(Duration(days: 45)),
        totalAnalyses: 6,
        status: 'Normal',
        phone: '+52 123 456 7894',
      ),
      Patient(
        id: 'p006',
        fullName: 'Laura Hernández',
        age: 55,
        email: 'laura.hernandez@email.com',
        lastVisit: DateTime.now().subtract(Duration(days: 10)),
        totalAnalyses: 18,
        status: 'Leve',
        phone: '+52 123 456 7895',
      ),
    ];
  }
}
