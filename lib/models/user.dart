class User {
  final int id;
  final String name;
  final String email;
  final String role; // admin, user
  final String primaryCurrency;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    required this.primaryCurrency,
  });

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      primaryCurrency: json['primary_currency'] ?? 'IDR',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'primary_currency': primaryCurrency,
  };
}

