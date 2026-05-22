import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/pharmacist/pharmacist_home.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SanjeevaniApp());
}

class SanjeevaniApp extends StatelessWidget {
  const SanjeevaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sanjeevani Nexus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  Future<bool> _resolveSession() async {
    final auth = AuthService();
    final isLoggedIn = await auth.isLoggedIn();
    if (!isLoggedIn) return false;

    // Keep profile aligned with dashboard/auth service for the same login id.
    await auth.refreshGoogleUserFromBackend();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _resolveSession(),
      builder: (context, snapshot) {
        if (snapshot.data ?? false) {
          return const PharmacistHome();
        }

        return const WelcomeScreen();
      },
    );
  }
}
