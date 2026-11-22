enum UserRole {
  hospitalAdministrator,
  transplantCoordinator,
  bloodBankOfficer,
  emergencyIcuCoordinator,
  equipmentCoordinator,
  networkAdministrator,
  auditorComplianceOfficer,
}

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
    UserRole.hospitalAdministrator => 'Hospital Administrator',
    UserRole.transplantCoordinator => 'Transplant Coordinator',
    UserRole.bloodBankOfficer => 'Blood Bank Officer',
    UserRole.emergencyIcuCoordinator => 'Emergency/ICU Coordinator',
    UserRole.equipmentCoordinator => 'Equipment Coordinator',
    UserRole.networkAdministrator => 'Network Administrator',
    UserRole.auditorComplianceOfficer => 'Auditor/Compliance Officer',
  };
}

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String hprId; // Healthcare Professional Registry ID
  final UserRole role;
  final String affiliatedHospitalId;
  final String affiliatedHospitalName;
  final String department;
  final bool isVerified;
  final bool isProfileComplete;
  final DateTime lastLoginAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.hprId,
    required this.role,
    required this.affiliatedHospitalId,
    required this.affiliatedHospitalName,
    required this.department,
    this.isVerified = true,
    this.isProfileComplete = false,
    required this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      hprId: json['hprId'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => throw FormatException('Unknown user role: ${json['role']}'),
      ),
      affiliatedHospitalId: json['affiliatedHospitalId'] as String,
      affiliatedHospitalName: json['affiliatedHospitalName'] as String,
      department: json['department'] as String,
      isVerified: json['isVerified'] as bool? ?? true,
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'hprId': hprId,
      'role': role.name,
      'affiliatedHospitalId': affiliatedHospitalId,
      'affiliatedHospitalName': affiliatedHospitalName,
      'department': department,
      'isVerified': isVerified,
      'isProfileComplete': isProfileComplete,
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? hprId,
    UserRole? role,
    String? affiliatedHospitalId,
    String? affiliatedHospitalName,
    String? department,
    bool? isVerified,
    bool? isProfileComplete,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      hprId: hprId ?? this.hprId,
      role: role ?? this.role,
      affiliatedHospitalId: affiliatedHospitalId ?? this.affiliatedHospitalId,
      affiliatedHospitalName: affiliatedHospitalName ?? this.affiliatedHospitalName,
      department: department ?? this.department,
      isVerified: isVerified ?? this.isVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
