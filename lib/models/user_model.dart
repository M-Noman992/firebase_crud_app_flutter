class User {
  final String name;
  final String email;
  final String phone;

  User({
    required this.name,
    required this.email,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? 'No email',
      phone: json['phone'] ?? 'No phone',
    );
  }
}