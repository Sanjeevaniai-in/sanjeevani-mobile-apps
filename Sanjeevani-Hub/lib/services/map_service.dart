import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/config/api_config.dart';

/// Model for Rider location data
class RiderLocation {
  final String riderId;
  final String riderName;
  final double lat;
  final double lng;
  final bool isOnline;
  final double? accuracy;
  final String timestamp;

  RiderLocation({
    required this.riderId,
    required this.riderName,
    required this.lat,
    required this.lng,
    required this.isOnline,
    this.accuracy,
    required this.timestamp,
  });

  factory RiderLocation.fromJson(Map<String, dynamic> json) {
    return RiderLocation(
      riderId: json['rider_id'] as String? ?? json['officer_id'] as String? ?? 'unknown',
      riderName: json['rider_name'] as String? ?? json['officer_name'] as String? ?? 'Rider',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      isOnline: json['is_online'] as bool? ?? true,
      accuracy: json['accuracy'] != null
          ? (json['accuracy'] as num).toDouble()
          : null,
      timestamp:
          json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}

/// Pharmacy Tier Enum
enum PharmacyTier { base, pro, ultraPro }

/// Model for Pharmacy data
class Pharmacy {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final PharmacyTier tier;
  final String? whatsapp;
  final String? telegram;
  final String? phone;
  final String? address;
  final bool isOpen;
  final String distance;

  Pharmacy({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.tier,
    this.whatsapp,
    this.telegram,
    this.phone,
    this.address,
    this.isOpen = true,
    this.distance = '0.5 km',
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    // Parse tier from string
    final tierStr = (json['tier'] ?? 'base').toString().toLowerCase();
    PharmacyTier activeTier = PharmacyTier.base;
    if (tierStr.contains('ultra')) {
      activeTier = PharmacyTier.ultraPro;
    } else if (tierStr.contains('pro')) {
      activeTier = PharmacyTier.pro;
    }

    return Pharmacy(
      id: (json['pharmacy_id'] ?? json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? 'Unknown Pharmacy',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      tier: activeTier,
      whatsapp: json['whatsapp'],
      telegram: json['telegram'],
      phone: json['phone_number'] ?? json['phone'],
      address: json['address'],
      isOpen: json['is_active'] ?? json['is_open'] ?? true,
      distance: json['distance'] ?? '0.8 km',
    );
  }
}

/// Singleton service for managing map WebSocket connection
class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  bool _isConnected = false;
  bool _manuallyDisconnected = false;
  bool _isDisposed = false;
  Timer? _reconnectTimer;
  Future<void>? _connectFuture;

  // Streams for real-time updates
  final _ridersController =
      StreamController<Map<String, RiderLocation>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, RiderLocation>> get ridersStream =>
      _ridersController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;

  final Map<String, RiderLocation> _riders = {};
  List<Pharmacy> _pharmacies = [];
  static const double _nandedLat = 19.1383;
  static const double _nandedLng = 77.3210;

  Map<String, RiderLocation> get riders => Map.unmodifiable(_riders);
  List<Pharmacy> get loadedPharmacies => List.unmodifiable(_pharmacies);
  bool get isConnected => _isConnected;

  /// Connect to WebSocket
  Future<void> connect() async {
    if (_isDisposed) return;
    _manuallyDisconnected = false;
    if (_isConnected) return;
    if (_connectFuture != null) return _connectFuture!;

    _connectFuture = _connectInternal();
    await _connectFuture;
    _connectFuture = null;
  }

  Future<void> _connectInternal() async {
    try {
      _reconnectTimer?.cancel();
      await _channelSubscription?.cancel();
      _channelSubscription = null;
      try {
        await _channel?.sink.close();
      } catch (_) {}

      final wsUrl = ApiConfig.wsLocations;
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Wait for the first frame to confirm connection (non-blocking)
      await _channel!.ready.timeout(const Duration(seconds: 5));
      
      _isConnected = true;
      _connectionController.add(true);

      _channelSubscription = _channel!.stream.listen(
        (message) => _handleMessage(message),
        onError: (error) {
          debugPrint('MapService: WS Stream Error: $error');
          _handleDisconnection();
        },
        onDone: () => _handleDisconnection(),
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('MapService: Connection Error: $e');
      _handleDisconnection();
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'snapshot':
          _handleSnapshot(data);
          break;
        case 'rider_update':
        case 'officer_update':
          _handleRiderUpdate(data);
          break;
        case 'notification':
          if (!_notificationController.isClosed) {
            _notificationController.add(data);
          }
          break;
      }
    } catch (e) {
      print('MapService: Error handling message: $e');
    }
  }

  void _handleSnapshot(Map<String, dynamic> data) {
    if (data['riders'] != null) {
      final ridersList = data['riders'] as Map<String, dynamic>;
      ridersList.forEach((id, riderData) {
        _riders[id] = RiderLocation.fromJson(riderData);
      });
      if (!_ridersController.isClosed) {
        _ridersController.add(_riders);
      }
    } else if (data['officers'] != null) {
       final officersList = data['officers'] as Map<String, dynamic>;
      officersList.forEach((id, riderData) {
        _riders[id] = RiderLocation.fromJson(riderData);
      });
      if (!_ridersController.isClosed) {
        _ridersController.add(_riders);
      }
    }
  }

  void _handleRiderUpdate(Map<String, dynamic> data) {
    final rider = RiderLocation.fromJson(data);
    _riders[rider.riderId] = rider;
    if (!_ridersController.isClosed) {
      _ridersController.add(_riders);
    }
  }

  void _handleDisconnection() {
    _isConnected = false;
    if (!_connectionController.isClosed) {
      _connectionController.add(false);
    }
    _channel = null;

    _reconnectTimer?.cancel();
    if (_manuallyDisconnected || _isDisposed) return;

    // Attempt reconnection after delay
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_manuallyDisconnected && !_isDisposed) {
        connect();
      }
    });
  }

  void disconnect() {
    _manuallyDisconnected = true;
    _reconnectTimer?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channelSubscription?.cancel();
    _channelSubscription = null;
    _handleDisconnection();
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _ridersController.close();
    _connectionController.close();
    _notificationController.close();
  }

  /// Fetch pharmacies near a location
  Future<List<Pharmacy>> fetchNearbyPharmacies(double lat, double lng) async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.pharmaciesList));
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          _pharmacies = decoded
              .map((json) => Pharmacy.fromJson(json))
              .where((p) => p.lat != 0.0 || p.lng != 0.0)
              .toList();
        } else {
          _pharmacies = [];
        }
      } else {
        print('MapService: API Error ${response.statusCode}');
        _pharmacies = [];
      }
    } catch (e) {
      print('MapService: Error fetching pharmacies: $e');
      _pharmacies = [];
    }

    // fallback to demo shops near Nanded for stable demo UX
    if (_pharmacies.isEmpty) {
      _pharmacies = _buildNandedDemoPharmacies();
    }

    return _pharmacies;
  }

  List<Pharmacy> _buildNandedDemoPharmacies() {
    return [
      Pharmacy(
        id: ApiConfig.primaryPharmacyId,
        name: 'Sanjeevani Nexus Pharmacy - Nanded',
        lat: _nandedLat + 0.0020,
        lng: _nandedLng + 0.0014,
        tier: PharmacyTier.ultraPro,
        address: 'Vazirabad Main Road, Nanded',
        whatsapp: '919876543210',
        telegram: 'sanjeevani_nanded',
        phone: '+919876543210',
        distance: '0.4 km',
      ),
      Pharmacy(
        id: 'NANDED_DEMO_2',
        name: 'CarePlus Medical - Degloor Naka',
        lat: _nandedLat - 0.0018,
        lng: _nandedLng + 0.0022,
        tier: PharmacyTier.pro,
        address: 'Degloor Naka, Nanded',
        whatsapp: '919812345678',
        telegram: 'careplus_nanded',
        phone: '+919812345678',
        distance: '0.9 km',
      ),
      Pharmacy(
        id: 'NANDED_DEMO_3',
        name: 'Shiv Medico - ITI Corner',
        lat: _nandedLat + 0.0012,
        lng: _nandedLng - 0.0024,
        tier: PharmacyTier.base,
        address: 'ITI Corner, Nanded',
        distance: '1.2 km',
      ),
    ];
  }
}
