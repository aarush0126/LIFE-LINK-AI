import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user_model.dart';

class AuthFlowException implements Exception {
  final String message;

  const AuthFlowException(this.message);

  @override
  String toString() => message;
}

class DemoAccount {
  final UserRole role;
  final String fullName;
  final String email;
  final String hospitalName;
  final String department;
  final String hprId;

  const DemoAccount({
    required this.role,
    required this.fullName,
    required this.email,
    required this.hospitalName,
    required this.department,
    required this.hprId,
  });
}

const demoAccounts = <DemoAccount>[
  DemoAccount(
    role: UserRole.hospitalAdministrator,
    fullName: 'Alex Morgan',
    email: 'hospital.admin@lifelink.example',
    hospitalName: 'Northstar Teaching Hospital (Demo)',
    department: 'Hospital Operations (Demo)',
    hprId: 'DEMO-HPR-1001',
  ),
  DemoAccount(
    role: UserRole.transplantCoordinator,
    fullName: 'Jordan Lee',
    email: 'transplant.coordinator@lifelink.example',
    hospitalName: 'Cedar Valley Medical Center (Demo)',
    department: 'Transplant Coordination (Demo)',
    hprId: 'DEMO-HPR-1002',
  ),
  DemoAccount(
    role: UserRole.bloodBankOfficer,
    fullName: 'Taylor Reed',
    email: 'blood.officer@lifelink.example',
    hospitalName: 'Riverside Blood Center (Demo)',
    department: 'Blood Services (Demo)',
    hprId: 'DEMO-HPR-1003',
  ),
  DemoAccount(
    role: UserRole.emergencyIcuCoordinator,
    fullName: 'Casey Patel',
    email: 'icu.coordinator@lifelink.example',
    hospitalName: 'Summit Emergency Hospital (Demo)',
    department: 'Emergency and Critical Care (Demo)',
    hprId: 'DEMO-HPR-1004',
  ),
  DemoAccount(
    role: UserRole.equipmentCoordinator,
    fullName: 'Riley Chen',
    email: 'equipment.coordinator@lifelink.example',
    hospitalName: 'Meadowbrook Medical Center (Demo)',
    department: 'Clinical Equipment (Demo)',
    hprId: 'DEMO-HPR-1005',
  ),
  DemoAccount(
    role: UserRole.networkAdministrator,
    fullName: 'Avery Brooks',
    email: 'network.admin@lifelink.example',
    hospitalName: 'LIFE-LINK Demo Network',
    department: 'Network Operations (Demo)',
    hprId: 'DEMO-HPR-1006',
  ),
  DemoAccount(
    role: UserRole.auditorComplianceOfficer,
    fullName: 'Sam Rivera',
    email: 'compliance.auditor@lifelink.example',
    hospitalName: 'LIFE-LINK Demo Network',
    department: 'Compliance Review (Demo)',
    hprId: 'DEMO-HPR-1007',
  ),
];

class AuthController extends ChangeNotifier {
  UserModel? _currentUser;
  UserModel? _pendingRegistration;

  UserModel? get currentUser => _currentUser;
  UserModel? get pendingRegistration => _pendingRegistration;

  void setAuthenticatedUser(UserModel user) {
    _pendingRegistration = null;
    _currentUser = user;
    notifyListeners();
  }

  Future<void> signInDemo(UserRole role) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final account = demoAccounts.firstWhere((account) => account.role == role);
    _pendingRegistration = null;
    _currentUser = _userFromAccount(
      account,
      isVerified: true,
      isProfileComplete: true,
    );
    notifyListeners();
  }

  Future<void> registerDemo({
    required String fullName,
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (demoAccounts.any((account) => account.email == normalizedEmail)) {
      throw const AuthFlowException(
        'That fictional demo account already exists. Choose a different email.',
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    _currentUser = null;
    _pendingRegistration = UserModel(
      id: 'DEMO-REG-${DateTime.now().microsecondsSinceEpoch}',
      fullName: fullName.trim(),
      email: normalizedEmail,
      hprId: '',
      role: UserRole.hospitalAdministrator,
      affiliatedHospitalId: 'DEMO-HOSPITAL',
      affiliatedHospitalName: '',
      department: '',
      isVerified: false,
      isProfileComplete: false,
      lastLoginAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> requestPasswordResetDemo(String email) async {
    if (email.trim().isEmpty) {
      throw const AuthFlowException(
        'Enter the email address used for this account.',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  Future<void> resendVerificationDemo() async {
    if (_pendingRegistration == null) {
      throw const AuthFlowException(
        'There is no pending demo registration to verify.',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  Future<void> verifyEmailDemo() async {
    final pending = _pendingRegistration;
    if (pending == null) {
      throw const AuthFlowException(
        'There is no pending demo registration to verify.',
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    _currentUser = pending.copyWith(isVerified: true, isProfileComplete: false);
    _pendingRegistration = null;
    notifyListeners();
  }

  Future<void> completeDemoProfile({
    required UserRole role,
    required String hospitalName,
    required String department,
    required String hprId,
  }) async {
    final user = _currentUser;
    if (user == null || !user.isVerified) {
      throw const AuthFlowException(
        'Verify the demo email before completing the profile.',
      );
    }
    if (role == UserRole.networkAdministrator ||
        role == UserRole.auditorComplianceOfficer) {
      throw const AuthFlowException(
        'Privileged demo roles can only be assigned to predefined demo accounts.',
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    _currentUser = user.copyWith(
      role: role,
      affiliatedHospitalName: hospitalName.trim(),
      department: department.trim(),
      hprId: hprId.trim(),
      isProfileComplete: true,
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    _currentUser = null;
    _pendingRegistration = null;
    notifyListeners();
  }

  UserModel _userFromAccount(
    DemoAccount account, {
    required bool isVerified,
    required bool isProfileComplete,
  }) {
    return UserModel(
      id: 'DEMO-${account.role.name}',
      fullName: account.fullName,
      email: account.email,
      hprId: account.hprId,
      role: account.role,
      affiliatedHospitalId: 'DEMO-${account.role.name.toUpperCase()}',
      affiliatedHospitalName: account.hospitalName,
      department: account.department,
      isVerified: isVerified,
      isProfileComplete: isProfileComplete,
      lastLoginAt: DateTime.now(),
    );
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  final controller = AuthController();
  ref.onDispose(controller.dispose);
  return controller;
});
