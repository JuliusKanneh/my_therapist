// lib/app/ui/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6C63FF); // Calming purple
  static const Color primaryLight = Color(0xFF9C96FF);
  static const Color primaryDark = Color(0xFF4A42CC);

  static const Color secondary = Color(0xFF00D4AA); // Healing green
  static const Color secondaryLight = Color(0xFF4DFFCF);
  static const Color secondaryDark = Color(0xFF00A384);

  static const Color accent = Color(0xFFFF6B9D); // Warm pink for emphasis
  static const Color accentLight = Color(0xFFFFB3D1);
  static const Color accentDark = Color(0xFFE0578A);

  // Therapeutic gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient calmingGradient = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient healingGradient = LinearGradient(
    colors: [secondary, Color(0xFF4ECDC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Neutral colors
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F8);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Chat colors
  static const Color userBubble = primary;
  static const Color aiBubble = Color(0xFFF1F3F4);
  static const Color typingIndicator = Color(0xFFE5E7EB);

  // Crisis colors
  static const Color crisisRed = Color(0xFFDC2626);
  static const Color crisisBackground = Color(0xFFFEF2F2);
  static const Color crisisBorder = Color(0xFFFECACA);
}
