import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
/// Model for authenticated user
class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String role;
  final String? age;
  final String? address;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    this.age,
    this.address,
  });

  factory User.fromJson(Map<String, dynamic> json, String role) {
    return User(
      id: (json['id'] ?? json['_id'] ?? json['user_id'] ?? '').toString(),
      name: json['name'] as String? ?? json['full_name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      photoUrl: json['photo_url'] as String? ?? json['picture'] as String? ?? json['avatar'] as String?,
      role: role,
      age: json['age'] as String? ?? (json['age'] != null ? json['age'].toString() : null),
      address: json['address'] as String?,
    );
  }
}

/// Shared helper to access the authenticated user's data from secure storage.
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final _storage = const FlutterSecureStorage();
  
  // For reactive updates
  final _userController = StreamController<User?>.broadcast();
  Stream<User?> get userStream => _userController.stream;

  Future<Map<String, dynamic>?> get userData async {
    final raw = await _storage.read(key: 'user_data');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<User?> get currentUser async {
    final data = await userData;
    if (data == null) return null;
    final r = await role;
    final user = User.fromJson(data, r);
    _userController.add(user);
    return user;
  }

  Future<String> get name async => (await currentUser)?.name ?? 'User';
  Future<String> get email async => (await currentUser)?.email ?? '';
  Future<String?> get photoUrl async => (await currentUser)?.photoUrl;

  Future<String?> get userId async => (await currentUser)?.id;

  Future<String> get role async {
    return await _storage.read(key: 'user_role') ?? 'customer';
  }

  Future<String?> get token async {
    return await _storage.read(key: 'auth_token');
  }
  
  void notifyUpdate() async {
    final user = await currentUser;
    _userController.add(user);
  }
}
