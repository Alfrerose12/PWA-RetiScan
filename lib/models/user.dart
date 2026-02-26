class User {
  final String id;
  final String email;
  final String role; // "MEDICO" | "PACIENTE"
  final String? fullName;
  final String? token;

  User({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.token,
  });

  // La API devuelve role como "MEDICO" o "PACIENTE"
  bool get isDoctor => role == 'MEDICO';
  bool get isClient => role == 'PACIENTE';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      if (fullName != null) 'fullName': fullName,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'PACIENTE',
      fullName: json['fullName'] as String?,
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? role,
    String? fullName,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      token: token ?? this.token,
    );
  }
}