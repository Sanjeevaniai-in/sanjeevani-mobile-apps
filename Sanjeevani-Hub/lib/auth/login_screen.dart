import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/services/auth_service.dart';
import 'role_select_screen.dart';
import 'short_register_screen.dart';
import '../delivery/delivery_home.dart';
import '../customer/customer_home.dart';

class LoginScreen extends StatefulWidget {
  final UserRole role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  bool get _isDelivery => widget.role == UserRole.deliveryPartner;
  String get _roleName => _isDelivery ? 'Delivery Partner' : 'Customer';
  
  List<Color> get _gradientColors => _isDelivery 
      ? [const Color(0xFFFF8A00), const Color(0xFF8B5CF6)]
      : [const Color(0xFF0066FF), const Color(0xFF4338CA)];

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    
    // Pass role to googleLogin for database separation
    final roleString = _isDelivery ? 'delivery' : 'customer';
    final result = await _authService.googleLogin(roleString);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      // Check if profile is complete (simulated via backend response or missing user field)
      final user = result['user'];
      final isNewUser = user['address'] == null || user['age'] == null;

      if (isNewUser) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ShortRegisterScreen(role: widget.role),
          ),
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => _isDelivery ? DeliveryHome() : const CustomerHome(),
          ),
          (_) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gradientColors[0].withOpacity(0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF374151), size: 20),
                    ),
                  ).animate().fadeIn(),

                  const SizedBox(height: 40),
                  
                  // App Branding
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _gradientColors[0].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _isDelivery ? Icons.delivery_dining_rounded : Icons.medical_services_rounded,
                      color: _gradientColors[0],
                      size: 32,
                    ),
                  ).animate().fadeIn().scale(),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    'Sanjeevani\n$_roleName',
                    style: GoogleFonts.outfit(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F2937),
                      height: 1.0,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    _isDelivery 
                      ? 'Earn by delivering essential medicines to those in need.'
                      : 'Get authentic medicines delivered safely to your home.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const Spacer(),
                  
                  // The "Asking" UI
                  Text(
                    'Continue with your Google account',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  
                  const SizedBox(height: 16),
                  
                  // Single Google Button
                  _buildGoogleButton()
                      .animate()
                      .fadeIn(delay: 800.ms)
                      .slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return _isLoading
        ? Center(
            child: CircularProgressIndicator(color: _gradientColors[0]),
          )
        : SizedBox(
            width: double.infinity,
            height: 64,
            child: OutlinedButton(
              onPressed: _handleGoogleLogin,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.white,
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://www.google.com/images/branding/googleg/1x/googleg_standard_color_128dp.png',
                    height: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
