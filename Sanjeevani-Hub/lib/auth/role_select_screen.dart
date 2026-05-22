import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

enum UserRole { customer, deliveryPartner }

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  UserRole? _selectedRole;

  void _proceed() {
    if (_selectedRole == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoginScreen(role: _selectedRole!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
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

              Text(
                'Who are\nyou? 🤔',
                style: GoogleFonts.outfit(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1F2937),
                  height: 1.1,
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 10),

              Text(
                'Choose your role to get the right experience.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF6B7280),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 40),

              // Customer Card
              _RoleCard(
                role: UserRole.customer,
                selected: _selectedRole == UserRole.customer,
                emoji: '🛒',
                title: 'Customer',
                subtitle:
                    'Order medicines, track deliveries, manage prescriptions',
                gradientColors: const [Color(0xFF0066FF), Color(0xFF4338CA)],
                onTap: () => setState(() => _selectedRole = UserRole.customer),
              ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),

              const SizedBox(height: 16),

              // Delivery Partner Card
              _RoleCard(
                role: UserRole.deliveryPartner,
                selected: _selectedRole == UserRole.deliveryPartner,
                emoji: '🚴',
                title: 'Delivery Partner',
                subtitle: 'Accept orders, navigate with live map, earn money',
                gradientColors: const [Color(0xFFFF8A00), Color(0xFF8B5CF6)],
                onTap: () =>
                    setState(() => _selectedRole = UserRole.deliveryPartner),
              ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),

              const Spacer(),

              // Continue Button
              AnimatedOpacity(
                opacity: _selectedRole != null ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 300),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _selectedRole == UserRole.deliveryPartner
                            ? [const Color(0xFFFF8A00), const Color(0xFF8B5CF6)]
                            : [
                                const Color(0xFF0066FF),
                                const Color(0xFF4338CA),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: _selectedRole != null
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0066FF).withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: _selectedRole != null ? _proceed : null,
                      child: Text(
                        'Continue',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final bool selected;
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? gradientColors[0].withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? gradientColors[0] : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Emoji container
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(colors: gradientColors)
                    : null,
                color: selected ? null : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? gradientColors[0]
                          : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Check indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? gradientColors[0] : Colors.transparent,
                border: Border.all(
                  color: selected ? gradientColors[0] : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
