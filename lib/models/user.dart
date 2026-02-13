class User {
  final String id;
  final String fullName;
  final int age;
  final String email;
  final String? profileImage;
  final String role; // "client" or "doctor"

  User({
    required this.id,
    required this.fullName,
    required this.age,
    required this.email,
    this.profileImage,
    this.role = "client", // Default to client
  });

  bool get isDoctor => role == "doctor";
  bool get isClient => role == "client";

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'age': age,
      'email': email,
      'profileImage': profileImage,
      'role': role,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      age: json['age'] as int,
      email: json['email'] as String,
      profileImage: json['profileImage'] as String?,
      role: json['role'] as String? ?? "client",
    );
  }

  User copyWith({
    String? id,
    String? fullName,
    int? age,
    String? email,
    String? profileImage,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
    );
  }
}