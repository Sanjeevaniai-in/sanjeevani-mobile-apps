import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message received: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // WebSocket for real-time notifications
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Local notifications plugin
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Firebase Messaging
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _manuallyDisconnected = false;
  Timer? _reconnectTimer;
  String? _currentRiderId;
  String? _fcmToken;

  /// Stream of incoming notifications
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;

  /// Initialize the notification service
  Future<void> initialize(String riderId) async {
    if (_isInitialized && _currentRiderId == riderId) return;
    if (_isDisposed) return;

    _currentRiderId = riderId;
    _manuallyDisconnected = false;

    // Initialize Firebase Cloud Messaging
    await _initializeFirebaseMessaging();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Connect to WebSocket for real-time updates
    await _connectWebSocket();

    _isInitialized = true;
    print('✅ NotificationService initialized for rider: $riderId');
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: true,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        _fcmToken = await _firebaseMessaging.getToken();
        if (_fcmToken != null && _currentRiderId != null) {
          await _registerFCMToken(_fcmToken!);
        }

        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          if (_currentRiderId != null) {
            _registerFCMToken(newToken);
          }
        });

        FirebaseMessaging.onMessage.listen(_handleForegroundFCMMessage);
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
        FirebaseMessaging.onMessageOpenedApp.listen(_handleFCMNotificationTap);

        RemoteMessage? initialMessage = await _firebaseMessaging
            .getInitialMessage();
        if (initialMessage != null) {
          _handleFCMNotificationTap(initialMessage);
        }
      }
    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }

  /// Register FCM token with backend
  Future<void> _registerFCMToken(String token) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/fcm/register-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rider_id': _currentRiderId,
          'fcm_token': token,
          'device_info': {
            'platform': 'android',
            'registered_at': DateTime.now().toIso8601String(),
          },
        }),
      );
    } catch (e) {
      print('❌ Error registering FCM token: $e');
    }
  }

  void _handleForegroundFCMMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        isEmergency: data['notification_type'] == 'emergency',
        payload: jsonEncode(data),
      );

      if (!_notificationController.isClosed) {
        _notificationController.add({
          'title': notification.title,
          'message': notification.body,
          'notification_type': data['notification_type'] ?? 'normal',
          ...data,
          'received_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  void _handleFCMNotificationTap(RemoteMessage message) {
    final data = message.data;
    if (!_notificationController.isClosed) {
      _notificationController.add({
        ...data,
        'tapped': true,
        'received_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      const normalChannel = AndroidNotificationChannel(
        'sanjeevani_notifications',
        'Notifications',
        description: 'General notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      const emergencyChannel = AndroidNotificationChannel(
        'sanjeevani_emergency',
        'Urgent Alerts',
        description: 'Critical alerts for riders',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFDC2626),
      );

      await androidPlugin.createNotificationChannel(normalChannel);
      await androidPlugin.createNotificationChannel(emergencyChannel);
    }
  }

  /// WebSocket Logic
  Future<void> _connectWebSocket() async {
    if (_isDisposed || _manuallyDisconnected) return;
    try {
      _reconnectTimer?.cancel();
      await _channelSubscription?.cancel();
      _channelSubscription = null;
      try {
        await _channel?.sink.close();
      } catch (_) {}

      _channel = WebSocketChannel.connect(Uri.parse(ApiConfig.wsNotifications));
      _channelSubscription = _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _handleWebSocketMessage(data);
          } catch (e) {
            print('❌ Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _reconnectWebSocket();
        },
        onDone: _reconnectWebSocket,
        cancelOnError: true,
      );
    } catch (e) {
      _reconnectWebSocket();
    }
  }

  void _reconnectWebSocket() {
    _reconnectTimer?.cancel();
    if (!_isInitialized || _isDisposed || _manuallyDisconnected) return;
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_isInitialized && !_isDisposed && !_manuallyDisconnected) {
        _connectWebSocket();
      }
    });
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == 'notification') {
      _handleNotification(data);
    } else if (type == 'rider_alert') {
      _handleRiderAlert(data);
    }
  }

  void _handleNotification(Map<String, dynamic> data) {
    final targetRiderIds =
        data['target_rider_ids'] as List? ??
        data['target_officer_ids'] as List?;

    if (targetRiderIds != null &&
        _currentRiderId != null &&
        !targetRiderIds.map((id) => id.toString()).contains(_currentRiderId)) {
      return;
    }

    if (!_notificationController.isClosed) {
      _notificationController.add(data);
    }
    _showLocalNotification(
      title: data['title'] ?? 'Notification',
      body: data['message'] ?? '',
      isEmergency: data['notification_type'] == 'emergency',
      payload: jsonEncode(data),
    );
  }

  void _handleRiderAlert(Map<String, dynamic> data) {
    final riderName =
        data['rider_name'] as String? ??
        data['officer_name'] as String? ??
        'Rider';
    if (!_notificationController.isClosed) {
      _notificationController.add(data);
    }
    _showLocalNotification(
      title: '🚨 ALERT - $riderName',
      body: data['message_text'] ?? 'Alert at (${data['lat']}, ${data['lng']})',
      isEmergency: true,
      payload: jsonEncode(data),
    );
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required bool isEmergency,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      isEmergency ? 'sanjeevani_emergency' : 'sanjeevani_notifications',
      isEmergency ? 'Urgent Alerts' : 'Notifications',
      importance: isEmergency ? Importance.max : Importance.high,
      priority: isEmergency ? Priority.max : Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      color: isEmergency ? const Color(0xFFDC2626) : const Color(0xFF00D4FF),
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        if (!_notificationController.isClosed) {
          _notificationController.add({...data, 'tapped': true});
        }
      } catch (e) {}
    }
  }

  /// Fetch history
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    if (_currentRiderId == null) return [];
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/$_currentRiderId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['notifications'] as List).cast<Map<String, dynamic>>();
      }
    } catch (e) {}
    return [];
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/notifications/$notificationId/read',
        ),
      );
    } catch (e) {}
  }

  void dispose() {
    _isDisposed = true;
    _manuallyDisconnected = true;
    _reconnectTimer?.cancel();
    try {
      _channel?.sink.close(status.goingAway);
    } catch (_) {}
    _channelSubscription?.cancel();
    _channelSubscription = null;
    if (!_notificationController.isClosed) {
      _notificationController.close();
    }
    _isInitialized = false;
  }
}
