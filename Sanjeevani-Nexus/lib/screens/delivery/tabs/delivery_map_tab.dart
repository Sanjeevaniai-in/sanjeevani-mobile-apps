import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class DeliveryMapTab extends StatelessWidget {
  const DeliveryMapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              // Mock Map Background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9), // Light background to mimic map
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://raw.githubusercontent.com/flutter/website/main/src/assets/images/docs/ui/maps/map-location-1.png',
                      ),
                      fit: BoxFit.cover,
                      opacity: 0.8,
                    ),
                  ),
                ),
              ),

              // Mock Map Route & Pins overlay
              Positioned(
                top: 150,
                left: 100,
                child: _MapPin(
                  icon: Icons.local_pharmacy_rounded,
                  color: AppTheme.darkGreen,
                  label: 'Pharmacy',
                ),
              ),
              Positioned(
                bottom: 250,
                right: 80,
                child: _MapPin(
                  icon: Icons.location_on_rounded,
                  color: AppTheme.red,
                  label: 'Drop-off',
                  pulse: true,
                ),
              ),
              Positioned(
                top: 250,
                left: 180,
                child: _MapPin(
                  icon: Icons.moped_rounded,
                  color: AppTheme.cyan,
                  label: 'You',
                  isVehicle: true,
                ),
              ),

              // Notification Bubble Overlay
              Positioned(
                top: 20,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkGreen.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.cyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.assistant_direction_rounded,
                          color: AppTheme.cyan,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Turn right in 200m',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Onto Maple Street',
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Tracking Card
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ETA 7 mins',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.darkGreen,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '1.2 km away • Drop-off 1 of 3',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.amber.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.phone_rounded,
                              color: AppTheme.amber,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32, color: Color(0xFFE5E7EB)),
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'SJ',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sarah Jennings',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '124 Maple Street',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Slide to complete mockup
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.darkGreen,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                'Slide to Complete',
                                style: GoogleFonts.inter(
                                  color: AppTheme.neonGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 6,
                              top: 6,
                              bottom: 6,
                              child: Container(
                                width: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.neonGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.keyboard_double_arrow_right_rounded,
                                  color: AppTheme.darkGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool pulse;
  final bool isVehicle;

  const _MapPin({
    required this.icon,
    required this.color,
    required this.label,
    this.pulse = false,
    this.isVehicle = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget pin = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: isVehicle ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isVehicle ? BorderRadius.circular(8) : null,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        if (!isVehicle) ...[
          Container(
            width: 2,
            height: 12,
            color: color,
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );

    if (pulse) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.2),
        duration: const Duration(seconds: 1),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: pin,
        onEnd: () {
          // Restart animation (mock implementation)
        },
      );
    }

    return pin;
  }
}
