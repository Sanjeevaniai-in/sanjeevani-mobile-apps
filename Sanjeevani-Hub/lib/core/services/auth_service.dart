import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  final _googleSignIn = GoogleSignIn(
    clientId: '1051387626429-306jtdv2ctghn5h2tfurotthrcid2l2o.apps.googleusercontent.com',
    serverClientId: '1051387626429-306jtdv2ctghn5h2tfurotthrcid2l2o.apps.googleusercontent.com',
    scopes: ['email', 'profile', 'openid'],
  );

  static const String _appId = 'ops_hub';

  Future<String?> get token async => await _storage.read(key: 'auth_token');
  
  Future<String?> get userRole async => await _storage.read(key: 'user_role');

  Future<bool> get isAuthenticated async {
    final t = await token;
    final r = await userRole;
    return t != null && r != null;
  }

  Future<void> saveUserRole(String role) async {
    await _storage.write(key: 'user_role', value: role);
  }

  Future<Map<String, dynamic>?> googleLogin(String role) async {
    try {
      debugPrint('🚀 Starting Google Sign-In for role: $role');
      
      // Ensure clean state
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('⚠️ Google Sign-In aborted.');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        debugPrint('❌ FAILED: idToken is NULL.');
        return null;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.authBaseUrl}/auth/google/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': idToken,
          'app_id': _appId,
          'requested_role': role, // Critical for database separation
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Use backend user data if available
        Map<String, dynamic> userToSave = data['user'] ?? {};
        
        // FALLBACK: Inject Google metadata if backend fields are missing
        userToSave['name'] ??= googleUser.displayName;
        userToSave['picture'] ??= googleUser.photoUrl;
        userToSave['email'] ??= googleUser.email;
        
        await _storage.write(key: 'auth_token', value: data['access_token']);
        await _storage.write(key: 'user_data', value: jsonEncode(userToSave));
        await _storage.write(key: 'user_role', value: role);
        await _storage.write(key: 'user_name', value: userToSave['name']);
        
        return data;
      } else {
        debugPrint('❌ Backend Login Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('🔥 Google Login error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> signup({
    required String email,
    required String password,
    required String name,
    required String role,
    required String age,
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.authBaseUrl}/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'age': age,
          'address': address,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (latitude != null) 'lat': latitude,
          if (longitude != null) 'lng': longitude,
          'app_id': _appId,
          'requested_role': role,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'auth_token', value: data['access_token']);
        await _storage.write(key: 'user_data', value: jsonEncode(data['user']));
        await _storage.write(key: 'user_role', value: role);
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Signup error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.authBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'app_id': _appId,
          'requested_role': role,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'auth_token', value: data['access_token']);
        await _storage.write(key: 'user_data', value: jsonEncode(data['user']));
        await _storage.write(key: 'user_role', value: role);
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  Future<bool> completeSocialRegistration({
    required String role,
    required String name,
    required String age,
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final t = await token;
      if (t == null) return false;

      final response = await http.post(
        Uri.parse('${ApiConfig.authBaseUrl}/auth/complete-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $t',
        },
        body: jsonEncode({
          'role': role,
          'name': name,
          'age': age,
          'address': address,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (latitude != null) 'lat': latitude,
          if (longitude != null) 'lng': longitude,
          'app_id': _appId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'user_data', value: jsonEncode(data['user']));
        await _storage.write(key: 'user_name', value: name);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Registration Error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  Future<Map<String, dynamic>?> get currentUser async {
    final userData = await _storage.read(key: 'user_data');
    if (userData != null) {
      try {
        return jsonDecode(userData);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
