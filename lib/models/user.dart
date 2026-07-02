// lib/models/user.dart
class User {
  final String id;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final String? meterId;
  final String? customerId;

  User({
    required this.id,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.meterId,
    this.customerId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatarUrl'],
      meterId: json['meterId'],
      customerId: json['customerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'meterId': meterId,
      'customerId': customerId,
    };
  }
}