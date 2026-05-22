/// ─────────────────────────────────────────────────────────────────────────────
/// SINGLE SOURCE OF TRUTH for all backend URLs.
///
/// To switch environments, change [_activeEnv] only.
/// To update the ngrok URL, change [_ngrokUrl] only.
/// ─────────────────────────────────────────────────────────────────────────────

enum _Env { ngrok, local, production }

class ApiConfig {
  // ── Change this one line to switch environments ───────────────────────────
  static const _Env _activeEnv = _Env.ngrok;

  // ── URLs ──────────────────────────────────────────────────────────────────
  static const String _ngrokUrl =
      'https://michelina-decapodous-taren.ngrok-free.dev';
  static const String _localUrl =
      'http://10.0.2.2:8000'; // Android emulator → localhost
  static const String _productionUrl = 'https://sanjeevani-engine.onrender.com';

  static String get baseUrl {
    switch (_activeEnv) {
      case _Env.ngrok:
        return _ngrokUrl;
      case _Env.local:
        return _localUrl;
      case _Env.production:
        return _productionUrl;
    }
  }

  static const String apiPrefix = '/api/v1';
  static String get apiUrl => '$baseUrl$apiPrefix';

  // ── Endpoints ─────────────────────────────────────────────────────────────
  static String get ordersEndpoint => '$apiUrl/orders';
  static String get productsEndpoint => '$apiUrl/products';
  static String get customersEndpoint => '$apiUrl/customers';
  static String get dashboardEndpoint => '$apiUrl/dashboard';
  static String get alertsEndpoint => '$apiUrl/alerts';
  static String get authEndpoint => '$baseUrl/auth';

  // ── ngrok header (must be on every request when using ngrok) ─────────────
  /// Returns the extra header needed when [_activeEnv] is [_Env.ngrok].
  /// Always include this in every http call — it's a no-op on other envs.
  static Map<String, String> get extraHeaders => _activeEnv == _Env.ngrok
      ? const {'ngrok-skip-browser-warning': 'true'}
      : const {};
}
