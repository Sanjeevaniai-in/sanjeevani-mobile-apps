import 'api_config.dart';

/// Auth config — always uses the same base URL as the main API.
/// Never hardcode a URL here; change it in api_config.dart only.
class AuthApiConfig {
  static String get baseUrl => ApiConfig.baseUrl;
  static const String appId = 'storefront';
  static const String requestedRole = 'medical_owner';
}
