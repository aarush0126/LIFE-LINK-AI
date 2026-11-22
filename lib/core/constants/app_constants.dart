class AppConstants {
  AppConstants._();

  static const String appName = 'LIFE-LINK AI';
  static const String appTagline = 'National Healthcare Technology Platform';
  static const String appVersion = '1.0.0';

  // National Helplines & Authority References
  static const String nationalEmergencyNumber = '108';
  static const String organDonationTollFree = '1800-11-4770';
  static const String bloodBankHelpline = '104';
  static const String governingBody = 'National Organ & Tissue Transplant Organisation (NOTTO)';
  static const String healthMinistry = 'Ministry of Health & Family Welfare';

  // Timeouts & Durations
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration organIschemicCriticalWarningThreshold = Duration(hours: 4);

  // Pagination Defaults
  static const int defaultPageSize = 20;

  // Responsive Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;

  // Cache & Storage Keys
  static const String tokenKey = 'life_link_auth_token';
  static const String userKey = 'life_link_user_data';
  static const String themeModeKey = 'life_link_theme_mode';
}
