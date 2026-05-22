import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pharmacy_profile.dart';
import 'api_config.dart';
import 'auth_api_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _profileKey = 'pharmacy_profile';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _passwordKey = 'pharmacy_password';
  static const String _tokenKey = 'auth_token';
  static const String _googleUserKey = 'google_user';
  static const String _userRoleKey = 'user_role';
  static const String _googleClientId =
      '1051387626429-306jtdv2ctghn5h2tfurotthrcid2l2o.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: _googleClientId,
    serverClientId: _googleClientId,
    scopes: const ['email', 'profile', 'openid'],
  );

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null && token.isNotEmpty) return true;
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<PharmacyProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileKey);
    if (profileJson == null) return null;
    return PharmacyProfile.fromJson(
      json.decode(profileJson) as Map<String, dynamic>,
    );
  }

  Future<void> register({
    required PharmacyProfile profile,
    required String password,
    String? tempLogoPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    String? savedLogoPath;
    if (tempLogoPath != null) {
      savedLogoPath = await _persistLogo(tempLogoPath);
    }

    final finalProfile = savedLogoPath != null
        ? profile.copyWith(logoPath: savedLogoPath)
        : profile;

    await prefs.setString(_profileKey, json.encode(finalProfile.toJson()));
    await prefs.setString(_passwordKey, password);
    await prefs.setBool(_isLoggedInKey, true);
  }

  Future<bool> login(String phone, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = await getProfile();
    if (profile == null) return false;
    final storedPassword = prefs.getString(_passwordKey) ?? '';
    if (profile.phone == phone && storedPassword == password) {
      await prefs.setBool(_isLoggedInKey, true);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.setBool(_googleUserKey, false);
    await prefs.remove(_tokenKey);
    await prefs.remove(_googleUserKey);
    await prefs.remove(_userRoleKey);
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
    } catch (_) {}
  }

  Future<void> saveGoogleAuth(
      String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_googleUserKey, json.encode(userData));
    await prefs.setBool(_isLoggedInKey, true);

    final profile = PharmacyProfile(
      pharmacyName: userData['pharmacy_name'] ?? '',
      ownerName: userData['name'] ?? userData['owner_name'] ?? '',
      phone: userData['phone_number'] ?? '',
    );
    await prefs.setString(_profileKey, json.encode(profile.toJson()));
  }

  Future<Map<String, dynamic>?> fetchUserProfile(String token) async {
    final headers = {
      ...ApiConfig.extraHeaders,
      'Authorization': 'Bearer $token',
    };

    final contextUri = Uri.parse('${AuthApiConfig.baseUrl}/auth/me/context');
    final contextResponse = await http.get(contextUri, headers: headers);
    if (contextResponse.statusCode == 200) {
      final decoded = json.decode(contextResponse.body);
      if (decoded is Map<String, dynamic>) {
        final user = decoded['user'];
        if (user is Map<String, dynamic>) return user;
      }
    }

    final uri = Uri.parse('${AuthApiConfig.baseUrl}/auth/me');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) return null;
    final decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic>) {
      final user = decoded['user'];
      if (user is Map<String, dynamic>) return user;
      return decoded;
    }
    return null;
  }

  Future<Map<String, dynamic>?> refreshGoogleUserFromBackend() async {
    final token = await getGoogleToken();
    if (token == null || token.isEmpty) return null;

    final user = await fetchUserProfile(token);
    if (user == null) return null;

    await saveGoogleAuth(token, user);
    return user;
  }

  Future<String?> getGoogleToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, dynamic>?> getGoogleUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_googleUserKey);
    if (userJson == null) return null;
    return json.decode(userJson) as Map<String, dynamic>;
  }

  Future<String> _persistLogo(String tempPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final logoDir = Directory('${dir.path}/logos');
    if (!logoDir.existsSync()) logoDir.createSync(recursive: true);
    final ext = tempPath.split('.').last;
    final dest = '${logoDir.path}/pharmacy_logo.$ext';
    await File(tempPath).copy(dest);
    return dest;
  }

  Future<bool> googleLogin({String role = AuthApiConfig.requestedRole}) async {
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) return false;

      final response = await http.post(
        Uri.parse('${AuthApiConfig.baseUrl}/auth/google/token'),
        headers: {
          ...ApiConfig.extraHeaders,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_token': idToken,
          'app_id': AuthApiConfig.appId,
          'requested_role': role,
        }),
      );

      if (response.statusCode != 200) return false;
      final data = json.decode(response.body) as Map<String, dynamic>;
      final token = data['access_token']?.toString();
      if (token == null || token.isEmpty) return false;

      final backendUser = data['user'];
      Map<String, dynamic> userData = {};
      if (backendUser is Map<String, dynamic>) {
        userData = Map<String, dynamic>.from(backendUser);
      }
      userData['name'] ??= googleUser.displayName;
      userData['picture'] ??= googleUser.photoUrl;
      userData['email'] ??= googleUser.email;

      await saveGoogleAuth(token, userData);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userRoleKey, role);
      return true;
    } catch (_) {
      return false;
    }
  }
}
