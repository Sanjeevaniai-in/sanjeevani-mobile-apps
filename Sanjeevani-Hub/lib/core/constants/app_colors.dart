import 'package:flutter/material.dart';

class AppColors {
  // Primary - Clean White Foundation
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF8F9FA); // Ultra-light grey for depth
  static const Color cardLight = Colors.white;

  // Secondary & Brand Colors (Ordering System - Vibrant & Professional)
  static const Color primaryBlue = Color(0xFF0066FF); // Deep Trust Blue
  static const Color accentOrange = Color(0xFFFF8A00); // Food/Order Orange
  static const Color secondaryIndigo = Color(0xFF4338CA); // Royal Indigo
  static const Color vibrantPurple = Color(0xFF8B5CF6); // Modern Tech Purple
  
  // Status Colors
  static const Color successGreen = Color(0xFF10B981); // Emerald Green (Delivered)
  static const Color warningAmber = Color(0xFFF59E0B); // Amber (Pending)
  static const Color errorRed = Color(0xFFEF4444); // Rose Red (Cancelled)
  static const Color infoBlue = Color(0xFF3B82F6); // Info Blue

  // Text Colors
  static const Color textMain = Color(0xFF1F2937); // Dark Slate Grey
  static const Color textSub = Color(0xFF6B7280); // Cool Grey
  static const Color textLight = Color(0xFF9CA3AF); // Muted Grey

  // Decorative / Gradient Colors
  static const Color gradientStart = Color(0xFF0066FF);
  static const Color gradientEnd = Color(0xFF8B5CF6);
  static const Color shadowColor = Color(0x1A000000); // Very soft shadow
}
