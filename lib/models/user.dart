class User {
  final String id;
  final String username;
  final String? email;
  final String role; // "MEDICO" | "PACIENTE"
  final String? name;
  final bool isVerified;
  final bool mustChangePassword;
  final DateTime? subscriptionEndDate;
  final String? token;

  User({
    required this.id,
    required this.username,
    this.email,
    required this.role,
    this.name,
    this.isVerified = false,
    this.mustChangePassword = false,
    this.subscriptionEndDate,
    this.token,
  });

  bool get isDoctor  => role == 'MEDICO';
  bool get isPatient => role == 'PACIENTE';
  bool get isAdmin   => role == 'ADMINISTRADOR';

  /// Alias para compatibilidad con pantallas existentes
  String get fullName => name ?? username;

  factory User.fromJson(Map<String, dynamic> json) {
    DateTime? subEnd;
    final rawSub = json['subscription_end_date'] ?? json['subscriptionEndDate'];
    if (rawSub != null) subEnd = DateTime.tryParse(rawSub.toString());

    return User(
      id:                  (json['id'] ?? '').toString(),
      username:            (json['username'] ?? '').toString(),
      email:               json['email']?.toString(),
      role:                (json['role'] as String?) ?? 'PACIENTE',
      name:                (json['name'] ?? json['fullName'])?.toString(),
      isVerified:          json['is_verified'] == true || json['isVerified'] == true,
      mustChangePassword:  json['must_change_password'] == true || json['mustChangePassword'] == true,
      subscriptionEndDate: subEnd,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':       id,
    'username': username,
    if (email != null) 'email': email,
    'role':     role,
    if (name  != null) 'name': name,
  };

  User copyWith({
    String?   id,
    String?   username,
    String?   email,
    String?   role,
    String?   name,
    bool?     isVerified,
    bool?     mustChangePassword,
    DateTime? subscriptionEndDate,
    String?   token,
  }) {
    return User(
      id:                  id                  ?? this.id,
      username:            username             ?? this.username,
      email:               email               ?? this.email,
      role:                role                ?? this.role,
      name:                name                ?? this.name,
      isVerified:          isVerified          ?? this.isVerified,
      mustChangePassword:  mustChangePassword  ?? this.mustChangePassword,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      token:               token               ?? this.token,
    );
  }
}