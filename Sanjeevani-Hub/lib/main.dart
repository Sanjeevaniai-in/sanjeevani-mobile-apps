import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'delivery/delivery_home.dart';
import 'customer/customer_home.dart';
import 'auth/welcome_screen.dart';
import 'auth/role_select_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:app_links/app_links.dart';
import 'delivery/chatbot_page.dart';
import 'customer/customer_notifications_page.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 🔔 Notification Channel for High Importance
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description:
      'This channel is used for important notifications.', // description
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCva3gdyyGrF0rmMrip-28AduBOSQsvlX0",
          appId: "1:634382192687:android:abfecbb79214ccbd77b6da",
          messagingSenderId: "634382192687",
          projectId: "sanjeevani-c2a86",
        ),
      );
    }
  } catch (e) {
    debugPrint('Background Firebase init error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set Mapbox access token
  try {
    mapbox.MapboxOptions.setAccessToken(
      "pk.eyJ1Ijoic2FtYXkwMSIsImEiOiJjbW4xeWJpcDExMW1sMnJzZmFyeGljZTU3In0.TIsucT8Ce_c-XgfBtotOPw",
    );
  } catch (e) {
    debugPrint('Mapbox Token Error: $e');
  }

  // Initializations
  bool isFirstLaunch = true;
  bool isLoggedIn = false;
  String? userRole;

  try {
    final prefs = await SharedPreferences.getInstance();
    isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

    final authService = AuthService();
    isLoggedIn = await authService.isAuthenticated;
    userRole = await authService.userRole;

    await _initializeFirebase();
    await _setupLocalNotifications();
  } catch (e) {
    debugPrint('Startup Initialization Error: $e');
  }

  runApp(
    SanjeevaniDeliveryApp(
      isFirstLaunch: isFirstLaunch,
      isLoggedIn: isLoggedIn,
      userRole: userRole,
    ),
  );
}

Future<void> _initializeFirebase() async {
  try {
    // 🛡️ REINFORCED INITIALIZATION: Provide manual options as a fallback
    // to the native auto-init. This fixes the "Missing API Key" error.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCva3gdyyGrF0rmMrip-28AduBOSQsvlX0",
          appId: "1:634382192687:android:abfecbb79214ccbd77b6da",
          messagingSenderId: "634382192687",
          projectId: "sanjeevani-c2a86",
        ),
      );
    } else {
      debugPrint('Firebase already initialized by native SDK.');
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions for Android 13+
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and print the FCM Token for debugging/testing
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint('🚀 FCM TOKEN: $token');

    // ⚡ Real-Time Foreground Listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // 🔔 Always push to customer notifications inbox (works for both roles)
      addNotificationToCustomerInbox(message);

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('ℹ️ Firebase already initialized, continuing...');
    } else {
      debugPrint('❌ Firebase initialization failed: $e');
    }
  }
}

Future<void> _setupLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

class SanjeevaniDeliveryApp extends StatefulWidget {
  final bool isFirstLaunch;
  final bool isLoggedIn;
  final String? userRole;

  const SanjeevaniDeliveryApp({
    super.key,
    required this.isFirstLaunch,
    required this.isLoggedIn,
    this.userRole,
  });

  @override
  State<SanjeevaniDeliveryApp> createState() => _SanjeevaniDeliveryAppState();
}

class _SanjeevaniDeliveryAppState extends State<SanjeevaniDeliveryApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle incoming links when the app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('🔗 App Link received: $uri');
      _handleDeepLink(uri);
    });

    // Handle cold start init link
    try {
      final appLink = await _appLinks.getInitialLink();
      if (appLink != null) {
        debugPrint('🚀 Initial App Link: $appLink');
        // A slight delay so the navigator is fully built
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleDeepLink(appLink);
        });
      }
    } catch (e) {
      debugPrint('App Link Init Error: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'sanjeevani' && uri.host == 'order') {
      final med = uri.queryParameters['med'];
      final pharmacy = uri.queryParameters['pharmacy'];

      // Trigger a local notification
      flutterLocalNotificationsPlugin.show(
        999,
        'Prescription Added',
        'We have added $med to your current cart from $pharmacy!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );

      // Navigate
      // This routes the user directly to the chatbot where they can confirm the order
      if (widget.isLoggedIn && widget.userRole == 'customer') {
        _navigatorKey.currentState?.pushNamed(
          '/chatbot',
          arguments: {'med': med, 'pharmacy': pharmacy},
        );
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Sanjeevani',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _getInitialScreen(),
      routes: {
        '/role-select': (context) => const RoleSelectScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/chatbot': (context) =>
            const ChatbotPage(), // Ensure this route exists
      },
    );
  }

  Widget _getInitialScreen() {
    if (widget.isLoggedIn && widget.userRole != null) {
      if (widget.userRole == 'customer') {
        return const CustomerHome();
      } else {
        return DeliveryHome();
      }
    } else if (widget.isFirstLaunch) {
      return const WelcomeScreen();
    } else {
      return const RoleSelectScreen();
    }
  }
}
