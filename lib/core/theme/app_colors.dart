import 'package:material_ui/material_ui.dart';

/// Centralized Design System Color Tokens for LIFE-LINK AI
/// Premium, Futuristic, Enterprise-Grade Healthcare Technology Palette
class AppColors {
  AppColors._();

  // Core Brand Backgrounds
  static const Color bgPrimary = Color(0xFF081321);      // Deep void navy
  static const Color bgSecondary = Color(0xFF101F31);    // Elevated surface navy
  static const Color bgCard = Color(0xFF14283D);         // Glass card base
  static const Color bgCardHover = Color(0xFF183049);    // Hover card state
  static const Color bgInput = Color(0xFF0C1929);        // Recessed input field

  // Core Brand Accents
  static const Color accentPrimary = Color(0xFF16C7B5);  // Electric Teal / Life Cyan
  static const Color accentPrimaryLight = Color(0xFF45DFC3);
  static const Color accentPrimaryDark = Color(0xFF0E8A7D);
  static const Color accentGlow = Color(0x3316C7B5);     // 20% opacity glow

  static const Color accentSecondary = Color(0xFF3998F7);// Vibrant Enterprise Blue
  static const Color accentSecondaryLight = Color(0xFF67B0F9);
  static const Color accentSecondaryDark = Color(0xFF226EBA);
  static const Color secondaryGlow = Color(0x333998F7);

  // Typography Tokens
  static const Color textPrimary = Color(0xFFF4F7FB);    // High contrast crisp white-blue
  static const Color textSecondary = Color(0xFF9AAFC3);  // Muted steel slate
  static const Color textMuted = Color(0xFF627D98);      // De-emphasized placeholder
  static const Color textDisabled = Color(0xFF3E5268);

  // Semantic Status Tokens
  static const Color success = Color(0xFF27C98A);        // Medical emerald
  static const Color successLight = Color(0xFF103628);
  static const Color successGlow = Color(0x3327C98A);

  static const Color warning = Color(0xFFFFB547);        // Urgent amber
  static const Color warningLight = Color(0xFF3D2A10);
  static const Color warningGlow = Color(0x33FFB547);

  static const Color danger = Color(0xFFF06565);         // Critical emergency crimson
  static const Color dangerLight = Color(0xFF3B191B);
  static const Color dangerGlow = Color(0x33F06565);

  static const Color info = Color(0xFF3998F7);
  static const Color infoLight = Color(0xFF122842);

  // Glassmorphic Borders & Highlights
  static const Color borderSubtle = Color(0xFF1C3652);   // Standard card border
  static const Color borderLight = Color(0xFF26496E);    // Hover card border
  static const Color borderHighlight = Color(0x4016C7B5);// Focused glowing border
  static const Color borderGlass = Color(0x1AFFFFFF);    // Frosted glass top-edge

  // Specialized Healthcare Colors
  static const Color organCyan = Color(0xFF16C7B5);
  static const Color bloodRed = Color(0xFFF06565);
  static const Color icuBlue = Color(0xFF3998F7);
  static const Color equipmentAmber = Color(0xFFFFA927);
  static const Color aiPurple = Color(0xFFA855F7);
  static const Color aiPurpleGlow = Color(0x33A855F7);

  // Backward Compatibility Aliases
  static const Color primary = bgPrimary;
  static const Color primaryLight = bgSecondary;
  static const Color primaryDark = Color(0xFF040A12);
  static const Color accent = accentPrimary;
  static const Color accentLight = accentPrimaryLight;
  static const Color accentDark = accentPrimaryDark;
  static const Color emergencyRed = danger;
  static const Color emergencyRedLight = dangerLight;
  static const Color warningOrange = warning;
  static const Color successGreen = success;
  static const Color successGreenLight = successLight;
  static const Color backgroundDark = bgPrimary;
  static const Color surfaceDark = bgSecondary;
  static const Color cardDark = bgCard;
  static const Color borderDark = borderSubtle;
  static const Color dividerDark = borderSubtle;
  static const Color textPrimaryDark = textPrimary;
  static const Color textSecondaryDark = textSecondary;
  static const Color textTertiaryDark = textMuted;
  static const Color backgroundLight = bgPrimary;
  static const Color surfaceLight = bgSecondary;
  static const Color cardLight = bgCard;
  static const Color borderLightGray = borderSubtle;
  static const Color dividerLight = borderSubtle;
  static const Color textPrimaryLight = textPrimary;
  static const Color textSecondaryLight = textSecondary;
  static const Color textTertiaryLight = textMuted;
}
