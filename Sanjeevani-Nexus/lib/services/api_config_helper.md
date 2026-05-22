# API Configuration Helper

## Quick Configuration Guide

### 1. Local Development (Backend on same machine)

**For Desktop/Web:**
```dart
static const String baseUrl = 'http://localhost:8000';
```

**For Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

**For iOS Simulator:**
```dart
static const String baseUrl = 'http://localhost:8000';
```

### 2. Physical Device Testing

First, find your computer's IP address:

**Windows:**
```bash
ipconfig
# Look for "IPv4 Address" under your active network adapter
# Example: 192.168.1.100
```

**Mac/Linux:**
```bash
ifconfig
# or
ip addr show
# Look for inet address under your active network (usually en0 or wlan0)
# Example: 192.168.1.100
```

Then update `api_config.dart`:
```dart
static const String baseUrl = 'http://192.168.1.100:8000';
```

**Important:** Make sure your phone and computer are on the same WiFi network!

### 3. Production Deployment

When you deploy your backend to a server (e.g., Render, Heroku, AWS):

```dart
static const String baseUrl = 'https://your-backend-url.com';
```

Remove the port number (8000) as production servers typically use standard HTTPS port (443).

## Environment-Based Configuration (Advanced)

For better management, you can create different configurations:

### Option 1: Using Dart Environment Variables

Create `lib/services/api_config.dart`:
```dart
class ApiConfig {
  static const String _localUrl = 'http://localhost:8000';
  static const String _emulatorUrl = 'http://10.0.2.2:8000';
  static const String _productionUrl = 'https://your-backend-url.com';
  
  // Change this to switch environments
  static const Environment currentEnv = Environment.local;
  
  static String get baseUrl {
    switch (currentEnv) {
      case Environment.local:
        return _localUrl;
      case Environment.emulator:
        return _emulatorUrl;
      case Environment.production:
        return _productionUrl;
    }
  }
  
  static const String apiPrefix = '/api/v1';
  static String get apiUrl => '$baseUrl$apiPrefix';
  
  static String get ordersEndpoint => '$apiUrl/orders';
  static String get productsEndpoint => '$apiUrl/products';
  static String get customersEndpoint => '$apiUrl/customers';
  static String get dashboardEndpoint => '$apiUrl/dashboard';
}

enum Environment {
  local,
  emulator,
  production,
}
```

### Option 2: Using Flutter Flavors (Production-Ready)

Create different configurations for dev/staging/production:

**lib/config/dev_config.dart:**
```dart
class Config {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String environment = 'development';
}
```

**lib/config/prod_config.dart:**
```dart
class Config {
  static const String baseUrl = 'https://your-backend-url.com';
  static const String environment = 'production';
}
```

Then import the appropriate config based on build flavor.

## Testing Your Configuration

### 1. Test Backend Connection

Add this test function to your app:

```dart
Future<void> testBackendConnection() async {
  try {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/health'));
    if (response.statusCode == 200) {
      print('✅ Backend connected successfully!');
      print('Response: ${response.body}');
    } else {
      print('❌ Backend returned status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Failed to connect to backend: $e');
  }
}
```

### 2. Common Connection Issues

**Issue: "Connection refused"**
- Backend is not running
- Wrong IP address
- Firewall blocking connection

**Issue: "Network unreachable"**
- Phone and computer on different networks
- VPN interfering
- Mobile data instead of WiFi

**Issue: "Timeout"**
- Backend is slow to respond
- Network latency
- Increase timeout in http requests

## Backend CORS Configuration

Make sure your backend allows requests from your app:

In `Backend Folder/SanjeevaniRxAI System/.env`:
```env
CORS_ORIGINS=["*"]
```

For production, specify exact origins:
```env
CORS_ORIGINS=["https://your-app-domain.com"]
```

## Checklist Before Running

- [ ] Backend server is running
- [ ] Backend health check works: http://localhost:8000/health
- [ ] Correct baseUrl in api_config.dart
- [ ] Phone and computer on same network (for physical device)
- [ ] Internet permission in AndroidManifest.xml
- [ ] CORS configured in backend
- [ ] MongoDB is running and connected

## Quick Test Commands

```bash
# Test backend health
curl http://localhost:8000/health

# Test orders endpoint
curl http://localhost:8000/api/v1/orders

# Test from your phone's network (replace IP)
curl http://192.168.1.100:8000/health
```

## Need Help?

1. Check backend logs: `Backend Folder/SanjeevaniRxAI System/error.log`
2. Check Flutter console for errors
3. Verify API in browser: http://localhost:8000/api/v1/docs
4. Test with Postman or curl first
