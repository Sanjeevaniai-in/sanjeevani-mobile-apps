class ApiConfig {
  static const String baseUrl = 'https://sanjeevani-engine.onrender.com';
  static const String authBaseUrl = 'https://sanjeevani-auth.onrender.com';
  static const String engineBaseUrl = 'https://sanjeevani-engine.onrender.com';
  static const String whatsappBotBaseUrl = 'https://sanjeevani-whatsappchatbot.onrender.com';

  // Primary Pharmacy for this app
  static const String primaryPharmacyId = 'PHARM_69ca9aee5b539eb0d62facd9';

  // API Endpoints
  static const String sendOtp = '$baseUrl/api/send-otp';
  static const String verifyOtp = '$baseUrl/api/verify-otp';
  static const String register = '$baseUrl/api/register';
  static const String checkDevice = '$baseUrl/api/check-device';
  static const String bindDevice = '$baseUrl/api/officer/bind-device';
  static const String validateDevice = '$baseUrl/api/officer/validate-device';
  static const String resetDevice = '$baseUrl/api/officer/reset-device';

  // Orders — correct prefix is /api/v1/orders
  static const String ordersManual = '$engineBaseUrl/api/v1/orders/manual';
  static const String ordersList   = '$engineBaseUrl/api/v1/orders/';
  static String orderById(String id) => '$engineBaseUrl/api/v1/orders/$id';
  static const String pharmaciesList = '$authBaseUrl/auth/pharmacies';

  // Products / Inventory
  static const String productsList = '$engineBaseUrl/api/v1/products/';

  // Chat
  static const String chat = '$engineBaseUrl/api/v1/chat/';
  static const String chatbotFast = '$whatsappBotBaseUrl/chat/fast';
  static const String chatbotUploadPrescription =
      '$whatsappBotBaseUrl/chat/upload-prescription';

  // Rider Location Tracking
  static String riderLocation(String riderId) =>
      '$baseUrl/api/officers/$riderId/location';
  static String riderStatus(String riderId) =>
      '$baseUrl/api/officers/$riderId/status';

  static String riderDetails(String riderId) =>
      '$baseUrl/api/officer/$riderId/details';

  // WebSocket Endpoints
  static String get wsLocations =>
      baseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://') +
      '/ws/locations';
  static String get wsNotifications =>
      baseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://') +
      '/ws/notifications';

  // Timeout configurations
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
