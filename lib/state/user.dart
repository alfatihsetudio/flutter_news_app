// lib/state/user.dart
class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? emailVerifiedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.emailVerifiedAt,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] is String ? int.tryParse(j['id']) ?? 0 : (j['id'] ?? 0),
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        phone: j['phone'],
        address: j['address'],
        emailVerifiedAt: j['email_verified_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'email_verified_at': emailVerifiedAt,
      };
}
