import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_controller.dart';
import '../../authentication/domain/role_access_policy.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/models/user_model.dart';
import '../../hospitals/data/synthetic_hospital_network_data.dart';

class AdminInstitutionRecord {
  const AdminInstitutionRecord({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.modules,
    required this.verification,
    this.isEnabled = true,
  });

  final String id;
  final String name;
  final String location;
  final String type;
  final List<String> modules;
  final String verification;
  final bool isEnabled;

  AdminInstitutionRecord copyWith({
    String? name,
    String? location,
    String? type,
    List<String>? modules,
    String? verification,
    bool? isEnabled,
  }) => AdminInstitutionRecord(
    id: id,
    name: name ?? this.name,
    location: location ?? this.location,
    type: type ?? this.type,
    modules: modules ?? this.modules,
    verification: verification ?? this.verification,
    isEnabled: isEnabled ?? this.isEnabled,
  );
}

class AdminDemoUserRecord {
  const AdminDemoUserRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.institution,
    required this.role,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String email;
  final String institution;
  final UserRole role;
  final bool isActive;

  AdminDemoUserRecord copyWith({UserRole? role, bool? isActive}) =>
      AdminDemoUserRecord(
        id: id,
        name: name,
        email: email,
        institution: institution,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
      );
}

class AdminAuditEntry {
  const AdminAuditEntry({
    required this.id,
    required this.occurredAt,
    required this.actor,
    required this.action,
    required this.subject,
  });

  final String id;
  final DateTime occurredAt;
  final String actor;
  final String action;
  final String subject;
}

class AdminDemoController extends ChangeNotifier {
  AdminDemoController() {
    _resetInstitutions();
    _resetUsers();
    final now = DateTime.now();
    _auditEntries.addAll([
      AdminAuditEntry(
        id: 'DEMO-AUDIT-001',
        occurredAt: now.subtract(const Duration(hours: 3)),
        actor: 'Demo Network Administrator',
        action: 'Session opened',
        subject: 'Demo administration workspace',
      ),
      AdminAuditEntry(
        id: 'DEMO-AUDIT-002',
        occurredAt: now.subtract(const Duration(hours: 1)),
        actor: 'Demo Compliance Reviewer',
        action: 'Audit summary viewed',
        subject: 'Synthetic audit sample',
      ),
    ]);
  }

  List<AdminInstitutionRecord> _institutions = [];
  List<AdminDemoUserRecord> _users = [];
  final List<AdminAuditEntry> _auditEntries = [];
  int _nextAuditId = 3;
  int _nextInstitutionId = 11;

  List<AdminInstitutionRecord> get institutions =>
      List.unmodifiable(_institutions);
  List<AdminDemoUserRecord> get users => List.unmodifiable(_users);
  List<AdminAuditEntry> get auditEntries =>
      List.unmodifiable(_auditEntries.reversed);

  static const assignableRoles = [
    UserRole.hospitalAdministrator,
    UserRole.transplantCoordinator,
    UserRole.bloodBankOfficer,
    UserRole.emergencyIcuCoordinator,
    UserRole.equipmentCoordinator,
  ];

  void updateVerification({
    required UserRole actorRole,
    required String actorId,
    required String institutionId,
    required bool verified,
  }) {
    _requireNetworkAdministrator(actorRole);
    final index = _institutions.indexWhere((item) => item.id == institutionId);
    if (index == -1) throw StateError('Institution record was not found.');
    final institution = _institutions[index];
    _institutions[index] = institution.copyWith(
      verification: verified ? 'Demo-verified' : 'Pending review',
    );
    _recordAudit(
      actorId,
      verified ? 'Demo verification approved' : 'Demo verification reopened',
      institutionId,
    );
    notifyListeners();
  }

  void setInstitutionEnabled({
    required UserRole actorRole,
    required String actorId,
    required String institutionId,
    required bool enabled,
  }) {
    _requireNetworkAdministrator(actorRole);
    final index = _institutions.indexWhere((item) => item.id == institutionId);
    if (index == -1) throw StateError('Institution record was not found.');
    _institutions[index] = _institutions[index].copyWith(isEnabled: enabled);
    _recordAudit(
      actorId,
      enabled ? 'Demo institution enabled' : 'Demo institution paused',
      institutionId,
    );
    notifyListeners();
  }

  void addInstitution({
    required UserRole actorRole,
    required String actorId,
    required String name,
    required String location,
  }) {
    _requireNetworkAdministrator(actorRole);
    final cleanName = name.trim();
    final cleanLocation = location.trim();
    if (cleanName.isEmpty || cleanLocation.isEmpty) {
      throw StateError('Enter an institution name and location.');
    }
    final id = 'DEMO-HN-${_nextInstitutionId.toString().padLeft(4, '0')}';
    _nextInstitutionId++;
    _institutions = [
      ..._institutions,
      AdminInstitutionRecord(
        id: id,
        name: cleanName.endsWith('(Demo)') ? cleanName : '$cleanName (Demo)',
        location: '$cleanLocation · Illustrative',
        type: 'Demonstration institution',
        modules: const ['Hospital network directory'],
        verification: 'Pending review',
      ),
    ];
    _recordAudit(actorId, 'Synthetic institution added', id);
    notifyListeners();
  }

  void updateUserRole({
    required UserRole actorRole,
    required String actorId,
    required String userId,
    required UserRole newRole,
  }) {
    _requireNetworkAdministrator(actorRole);
    if (userId == actorId) {
      throw StateError('You cannot change your own role assignment.');
    }
    if (!assignableRoles.contains(newRole)) {
      throw StateError(
        'Network administrator and auditor roles cannot be assigned here.',
      );
    }
    final index = _users.indexWhere((user) => user.id == userId);
    if (index == -1) throw StateError('Demo user record was not found.');
    if (!assignableRoles.contains(_users[index].role)) {
      throw StateError('Privileged demo accounts cannot be reassigned.');
    }
    _users[index] = _users[index].copyWith(role: newRole);
    _recordAudit(actorId, 'Demo role assignment changed', userId);
    notifyListeners();
  }

  void setUserActive({
    required UserRole actorRole,
    required String actorId,
    required String userId,
    required bool active,
  }) {
    _requireNetworkAdministrator(actorRole);
    if (userId == actorId) {
      throw StateError('You cannot disable your own demo account.');
    }
    final index = _users.indexWhere((user) => user.id == userId);
    if (index == -1) throw StateError('Demo user record was not found.');
    if (!assignableRoles.contains(_users[index].role)) {
      throw StateError('Privileged demo accounts cannot be modified.');
    }
    _users[index] = _users[index].copyWith(isActive: active);
    _recordAudit(
      actorId,
      active ? 'Demo user enabled' : 'Demo user disabled',
      userId,
    );
    notifyListeners();
  }

  void resetDemoWorkspace({
    required UserRole actorRole,
    required String actorId,
  }) {
    _requireNetworkAdministrator(actorRole);
    _resetInstitutions();
    _resetUsers();
    _recordAudit(actorId, 'Admin demo workspace reset', 'Local demo records');
    notifyListeners();
  }

  void _requireNetworkAdministrator(UserRole role) {
    if (role != UserRole.networkAdministrator) {
      throw StateError('Network administrator access is required.');
    }
  }

  void _recordAudit(String actorId, String action, String subject) {
    _auditEntries.add(
      AdminAuditEntry(
        id: 'DEMO-AUDIT-${_nextAuditId.toString().padLeft(3, '0')}',
        occurredAt: DateTime.now(),
        actor: actorId == 'DEMO-networkAdministrator'
            ? 'Demo Network Administrator'
            : actorId == 'DEMO-auditorComplianceOfficer'
            ? 'Demo Compliance Reviewer'
            : 'Demo authorized administrator',
        action: action,
        subject: subject,
      ),
    );
    _nextAuditId++;
  }

  void _resetInstitutions() {
    _institutions = SyntheticHospitalNetworkData.hospitals
        .map(
          (hospital) => AdminInstitutionRecord(
            id: hospital.institutionId,
            name: hospital.name,
            location: hospital.locationLabel,
            type: hospital.type.label,
            modules: hospital.coordinationModules,
            verification: switch (hospital.verification) {
              DemoHospitalVerification.demoVerified => 'Demo-verified',
              DemoHospitalVerification.pending => 'Pending review',
              DemoHospitalVerification.reported => 'Reported · unverified',
            },
          ),
        )
        .toList();
  }

  void _resetUsers() {
    _users = demoAccounts
        .map(
          (account) => AdminDemoUserRecord(
            id: 'DEMO-${account.role.name}',
            name: account.fullName,
            email: account.email,
            institution: account.hospitalName,
            role: account.role,
          ),
        )
        .toList();
  }
}

final adminDemoControllerProvider = Provider<AdminDemoController>((ref) {
  final controller = AdminDemoController();
  ref.onDispose(controller.dispose);
  return controller;
});

String adminRouteLabel(String route) => switch (route) {
  RouteNames.dashboard => 'Overview',
  RouteNames.hospitals => 'Hospital network',
  RouteNames.organCoordination => 'Organ & tissue coordination',
  RouteNames.bloodBank => 'Blood bank',
  RouteNames.icuBeds => 'ICU & emergency beds',
  RouteNames.equipment => 'Medical equipment',
  RouteNames.aiAssistant => 'AI assistant',
  RouteNames.notifications => 'Notifications',
  RouteNames.reports => 'Reports',
  RouteNames.settings => 'Settings',
  _ => route,
};

Set<String> routesForAdminRole(UserRole role) =>
    RoleAccessPolicy.routesFor(role).map(adminRouteLabel).toSet();
