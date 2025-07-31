// lib/models/user.dart
class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final bool emailVerified;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.emailVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      emailVerified: json['email_verified'] == 1 || json['email_verified'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'role': role,
      'email_verified': emailVerified ? 1 : 0,
    };
  }
}
