import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String _defaultBaseUrl = 'http://127.0.0.1:8000/api/v1';

  static String get baseUrl {
    final configured = dotenv.env['API_BASE_URL']?.trim();
    return configured == null || configured.isEmpty
        ? _defaultBaseUrl
        : configured.replaceFirst(RegExp(r'/$'), '');
  }

  static const String register = '/auth/register';
  static const String token = '/auth/token';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String userProfile = '/auth/me';

  static const String roles = '/roles';
  static const String users = '/users';
  static const String hospitals = '/hospitals';
  static const String hospitalDetails = '/hospitals/{id}';
  static const String hospitalCapabilities = '/hospitals/{id}/capabilities';

  static const String bloodInventory = '/blood-bank/inventory';
  static const String bloodRequests = '/blood-bank/enquiries';
  static const String icuBeds = '/icu-beds';
  static const String bedEnquiries = '/icu-beds/enquiries';
  static const String equipment = '/equipment';
  static const String equipmentEnquiries = '/equipment/enquiries';
  static const String resourceReport = '/resources/status';

  static const String coordinationCases = '/coordination-cases';
  static const String aiResourceSearch = '/ai/resource-search';
  static const String aiDataQuality = '/ai/data-quality';
  static const String aiOperationalSummary = '/ai/operational-summary';

  static const String notifications = '/notifications';
  static const String markNotificationRead = '/notifications/{id}/read';
  static const String auditEvents = '/admin/audit-events';
  static const String systemHealth = '/admin/system-health';
}
