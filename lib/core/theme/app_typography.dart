import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'app_colors.dart';

/// Centralized Typography Hierarchy for LIFE-LINK AI
/// Clean, sharp, high-legibility enterprise typography
class AppTypography {
  AppTypography._();

  static TextTheme buildTextTheme([
    Color primaryColor = AppColors.textPrimary,
    Color secondaryColor = AppColors.textSecondary,
  ]) {
    final base = GoogleFonts.interTextTheme();

    return base.copyWith(
      // Ultra Display - Command Center metrics & hero banners
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: primaryColor,
        height: 1.2,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: primaryColor,
        height: 1.25,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: primaryColor,
        height: 1.3,
      ),

      // Headlines - Section titles & dashboard module headers
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: primaryColor,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: primaryColor,
      ),

      // Titles - Card headers, modal titles, table headers
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: primaryColor,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: primaryColor,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: secondaryColor,
      ),

      // Body - Clinical notes, descriptions, table rows
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: primaryColor,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        color: secondaryColor,
        height: 1.45,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        color: secondaryColor,
        height: 1.4,
      ),

      // Labels - Status badges, button text, timestamps
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: primaryColor,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: primaryColor,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: secondaryColor,
      ),
    );
  }

  // Monospaced TextStyle for medical codes, HLA match indices, telemetry values
  static TextStyle mono({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: -0.2,
    );
  }
}
