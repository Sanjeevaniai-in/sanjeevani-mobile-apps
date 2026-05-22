import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config/api_config.dart';

class DeliveryLocationService {
  final _storage = const FlutterSecureStorage();
  Timer? _locationTimer;
  bool _isTracking = false;

  /// Request location permissions
  Future<bool> requestPermissions() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are disabled - return false silently
        return false;
      }

      // Check permission status
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied - return false silently
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are permanently denied - return false silently
        return false;
      }

      return true;
    } catch (e) {
      // Catch any exceptions and return false silently
      print('Location permission error (non-critical): $e');
      return false;
    }
  }

  /// Start tracking delivery rider location
  Future<void> startTracking() async {
    if (_isTracking) {
      print('Location tracking already started');
      return;
    }

    // Get rider details from storage
    String? riderId = await _storage.read(key: 'rider_id') ?? 'default_rider';
    String? riderName =
        await _storage.read(key: 'rider_name') ?? 'Sanjeevani Rider';

    _isTracking = true;

    // Send initial online status
    await _sendStatus(riderId, riderName, isOnline: true);

    // Start periodic location updates (every 5 seconds)
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      try {
        _sendLocation(riderId, riderName);
      } catch (e) {
        // Error in timer - silently ignore
      }
    });
  }

  /// Stop tracking delivery rider location
  Future<void> stopTracking() async {
    if (!_isTracking) {
      return;
    }

    _isTracking = false;
    _locationTimer?.cancel();
    _locationTimer = null;

    // Send offline status
    String? riderId = await _storage.read(key: 'rider_id') ?? 'default_rider';
    String? riderName =
        await _storage.read(key: 'rider_name') ?? 'Sanjeevani Rider';

    await _sendStatus(riderId, riderName, isOnline: false);
  }

  /// Send location to backend
  Future<void> _sendLocation(String riderId, String riderName) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      // Using a generic endpoint for now or keeping it as is if API matches
      await http
          .post(
            Uri.parse(ApiConfig.riderLocation(riderId)),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'lat': position.latitude,
              'lng': position.longitude,
              'rider_name': riderName,
              'accuracy': position.accuracy,
            }),
          )
          .timeout(
            ApiConfig.connectionTimeout,
            onTimeout: () =>
                throw TimeoutException('Location update timed out'),
          );
    } catch (e) {
      // Error sending location - silently ignore
    }
  }

  /// Send online/offline status to backend
  Future<void> _sendStatus(
    String riderId,
    String riderName, {
    required bool isOnline,
  }) async {
    try {
      await http
          .post(
            Uri.parse(ApiConfig.riderStatus(riderId)),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'is_online': isOnline, 'rider_name': riderName}),
          )
          .timeout(
            ApiConfig.connectionTimeout,
            onTimeout: () => throw TimeoutException('Status update timed out'),
          );
    } catch (e) {
      // Error sending status - silently ignore
    }
  }

  bool get isTracking => _isTracking;
}
