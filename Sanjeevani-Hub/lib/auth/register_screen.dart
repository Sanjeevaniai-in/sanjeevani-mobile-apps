import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/services/auth_service.dart';
import 'role_select_screen.dart';
import '../delivery/delivery_home.dart';
import '../customer/customer_home.dart';

class RegisterScreen extends StatefulWidget {
  final UserRole role;
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  final _storage = const FlutterSecureStorage();

  bool get _isDelivery => widget.role == UserRole.deliveryPartner;

  List<Color> get _gradientColors => _isDelivery
      ? [const Color(0xFFFF8A00), const Color(0xFF8B5CF6)]
      : [const Color(0xFF0066FF), const Color(0xFF4338CA)];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<Position?> _tryGetCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final roleString = _isDelivery ? 'delivery' : 'customer';
      final position = await _tryGetCurrentPosition();
      final result = await _authService.signup(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: roleString,
        age: _ageController.text.trim(),
        address: _addressController.text.trim(),
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      if (result != null) {
        // Save additional details (phone) to storage if needed
        await _storage.write(
          key: 'user_phone',
          value: _phoneController.text.trim(),
        );
        
        if (_isDelivery) {
           final userData = result['user'];
           await _storage.write(key: 'rider_id', value: userData['pharmacy_id'] ?? 'default_rider');
           await _storage.write(key: 'rider_name', value: _nameController.text.trim());
        }

        if (!mounted) return;
        setState(() => _isLoading = false);

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) =>
                _isDelivery ? DeliveryHome() : const CustomerHome(),
          ),
          (_) => false,
        );
      } else {
        // 🚀 SMART CHECK: If signup fails, try logging in!
        final loginResult = await _authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: roleString,
        );

        if (loginResult != null) {
           // User already exists and password matches! Redirect to Dashboard.
           if (!mounted) return;
           setState(() => _isLoading = false);
           Navigator.of(context).pushAndRemoveUntil(
             MaterialPageRoute(
               builder: (_) => _isDelivery ? DeliveryHome() : const CustomerHome(),
             ),
             (_) => false,
           );
           return;
        }

        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email already exists. If this belongs to you, check your password.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Back
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF374151),
                      size: 20,
                    ),
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 32),

                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: _gradientColors),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isDelivery ? '🚴 Delivery Partner' : '🛒 Customer',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 16),

                Text(
                  'Almost\nThere! ✨',
                  style: GoogleFonts.outfit(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F2937),
                    height: 1.1,
                  ),
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 10),

                Text(
                  'Just a couple of details and you\'re all set.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF6B7280),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 40),

                // Name field
                _buildLabel('Full Name'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameController,
                  hint: 'e.g. Rahul Sharma',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter your name'
                      : null,
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 20),

                // Email field
                _buildLabel('Email Address'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hint: 'e.g. rahul@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter email';
                    if (!v.contains('@')) return 'Enter valid email';
                    return null;
                  },
                ).animate().fadeIn(delay: 340.ms),

                const SizedBox(height: 20),

                // Password field
                _buildLabel('Password'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Min. 6 characters',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter password';
                    if (v.trim().length < 6) return 'Min 6 characters required';
                    return null;
                  },
                ).animate().fadeIn(delay: 380.ms),

                const SizedBox(height: 20),

                // Phone field
                _buildLabel('Phone Number'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _phoneController,
                  hint: '10-digit mobile number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Enter phone number';
                    if (v.trim().length != 10)
                      return 'Enter valid 10-digit number';
                    return null;
                  },
                ).animate().fadeIn(delay: 420.ms),

                const SizedBox(height: 20),

                // Age field
                _buildLabel('Age'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _ageController,
                  hint: 'e.g. 25',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter age';
                    return null;
                  },
                ).animate().fadeIn(delay: 440.ms),

                const SizedBox(height: 20),

                // Address field
                _buildLabel('Full Address'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _addressController,
                  hint: 'Enter your delivery/pickup address',
                  icon: Icons.location_on_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter address';
                    return null;
                  },
                ).animate().fadeIn(delay: 460.ms),

                const SizedBox(height: 48),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: _gradientColors),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: _gradientColors[0].withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isDelivery
                                  ? 'Start Delivering'
                                  : 'Start Ordering',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                    ),
                  ),
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1F2937)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF9CA3AF),
          fontSize: 15,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
        suffixIcon: isPassword
            ? const Icon(Icons.visibility_off_outlined,
                color: Color(0xFF9CA3AF), size: 18)
            : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0066FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
