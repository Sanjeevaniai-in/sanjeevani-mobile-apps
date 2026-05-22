import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';

/// Central HTTP client.
/// Automatically injects:
///   - Bearer token (from AuthService)
///   - ngrok bypass header (from ApiConfig.extraHeaders, no-op on prod)
class ApiClient {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers({bool includeJson = true}) async {
    final token = await _authService.getGoogleToken();
    return {
      ...ApiConfig.extraHeaders,
      if (includeJson) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(Uri uri) async =>
      http.get(uri, headers: await _headers(includeJson: false));

  Future<http.Response> post(Uri uri, {Object? body}) async {
    final payload = body is String ? body : json.encode(body ?? {});
    return http.post(uri, headers: await _headers(), body: payload);
  }

  Future<http.Response> patch(Uri uri, {Object? body}) async {
    final payload = body is String ? body : json.encode(body ?? {});
    return http.patch(uri, headers: await _headers(), body: payload);
  }

  Future<http.Response> delete(Uri uri) async =>
      http.delete(uri, headers: await _headers(includeJson: false));
}
