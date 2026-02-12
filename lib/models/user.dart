class User {
  final String id;
  final String fullName;
  final int age;
  final String email;
  final String? profileImage;

  User({
    required this.id,
    required this.fullName,
    required this.age,
    required this.email,
    this.profileImage,
  });
}