import '../../../core/routing/route_names.dart';
import '../../../shared/models/user_model.dart';

class RoleAccessPolicy {
  RoleAccessPolicy._();

  static const _allOperationalRoutes = {
    RouteNames.dashboard,
    RouteNames.hospitals,
    RouteNames.organCoordination,
    RouteNames.bloodBank,
    RouteNames.icuBeds,
    RouteNames.equipment,
    RouteNames.aiAssistant,
    RouteNames.notifications,
    RouteNames.profile,
    RouteNames.reports,
    RouteNames.settings,
  };

  static const Map<UserRole, Set<String>> _routesByRole = {
    UserRole.hospitalAdministrator: {
      RouteNames.dashboard,
      RouteNames.hospitals,
      RouteNames.bloodBank,
      RouteNames.icuBeds,
      RouteNames.equipment,
      RouteNames.aiAssistant,
      RouteNames.notifications,
      RouteNames.profile,
      RouteNames.reports,
      RouteNames.settings,
    },
    UserRole.transplantCoordinator: {
      RouteNames.dashboard,
      RouteNames.hospitals,
      RouteNames.organCoordination,
      RouteNames.aiAssistant,
      RouteNames.notifications,
      RouteNames.profile,
      RouteNames.settings,
    },
    UserRole.bloodBankOfficer: {
      RouteNames.dashboard,
      RouteNames.hospitals,
      RouteNames.bloodBank,
      RouteNames.aiAssistant,
      RouteNames.notifications,
      RouteNames.profile,
      RouteNames.settings,
    },
    UserRole.emergencyIcuCoordinator: {
      RouteNames.dashboard,
      RouteNames.hospitals,
      RouteNames.bloodBank,
      RouteNames.icuBeds,
      RouteNames.equipment,
      RouteNames.aiAssistant,
      RouteNames.notifications,
      RouteNames.profile,
      RouteNames.settings,
    },
    UserRole.equipmentCoordinator: {
      RouteNames.dashboard,
      RouteNames.hospitals,
      RouteNames.equipment,
      RouteNames.notifications,
      RouteNames.profile,
      RouteNames.settings,
    },
    UserRole.networkAdministrator: {
      ..._allOperationalRoutes,
      RouteNames.admin,
      RouteNames.adminAudit,
    },
    UserRole.auditorComplianceOfficer: {
      RouteNames.dashboard,
      RouteNames.hospitals,
      RouteNames.notifications,
      RouteNames.profile,
      RouteNames.reports,
      RouteNames.settings,
      RouteNames.adminAudit,
    },
  };

  static Set<String> routesFor(UserRole role) => _routesByRole[role]!;

  static bool canAccess(UserRole role, String location) {
    return routesFor(role)
        .any((route) => location == route || location.startsWith('$route/'));
  }
}
