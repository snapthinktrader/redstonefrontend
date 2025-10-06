import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1E3A8A); // Deep Blue
  static const Color primaryLight = Color(0xFF3B82F6); // Light Blue
  static const Color primaryDark = Color(0xFF1E40AF); // Dark Blue
  
  // Secondary Colors
  static const Color secondary = Color(0xFFF59E0B); // Amber/Gold
  static const Color secondaryLight = Color(0xFFFBBF24);
  static const Color secondaryDark = Color(0xFFD97706);
  
  // Background Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color text = textPrimary; // Alias for compatibility
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF6B7280);
  static const Color greyLight = Color(0xFFE5E7EB);
  static const Color greyDark = Color(0xFF374151);
  
  // Border Colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFFCBD5E1);
  
  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF1E3A8A),
    Color(0xFF3B82F6),
  ];
  
  static const List<Color> secondaryGradient = [
    Color(0xFFF59E0B),
    Color(0xFFFBBF24),
  ];
  
  static const List<Color> successGradient = [
    Color(0xFF059669),
    Color(0xFF10B981),
  ];
  
  // Card Colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x1A000000);
  
  // Input Colors
  static const Color inputBackground = Color(0xFFF8FAFC);
  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color inputFocusBorder = Color(0xFF3B82F6);
  
  // Button Colors
  static const Color buttonPrimary = Color(0xFF1E3A8A);
  static const Color buttonSecondary = Color(0xFFF59E0B);
  static const Color buttonDisabled = Color(0xFFE5E7EB);
  
  // Crypto/Investment specific colors
  static const Color profit = Color(0xFF10B981);
  static const Color loss = Color(0xFFEF4444);
  static const Color pending = Color(0xFFF59E0B);
  static const Color completed = Color(0xFF10B981);
  static const Color cancelled = Color(0xFFEF4444);
  
  // Referral Colors
  static const Color referralBonus = Color(0xFF8B5CF6);
  static const Color levelUp = Color(0xFFF59E0B);
  static const Color milestone = Color(0xFF10B981);
  
  // Transparency Variants
  static Color primaryWithOpacity(double opacity) => primary.withValues(alpha: opacity);
  static Color secondaryWithOpacity(double opacity) => secondary.withValues(alpha: opacity);
  static Color successWithOpacity(double opacity) => success.withValues(alpha: opacity);
  static Color errorWithOpacity(double opacity) => error.withValues(alpha: opacity);
  static Color warningWithOpacity(double opacity) => warning.withValues(alpha: opacity);
  static Color infoWithOpacity(double opacity) => info.withValues(alpha: opacity);
  static Color blackWithOpacity(double opacity) => black.withValues(alpha: opacity);
  static Color whiteWithOpacity(double opacity) => white.withValues(alpha: opacity);
  static Color greyWithOpacity(double opacity) => grey.withValues(alpha: opacity);
}