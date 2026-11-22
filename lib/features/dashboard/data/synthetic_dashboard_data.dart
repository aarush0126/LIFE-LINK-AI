enum DemoVerificationStatus { institutionConfirmed, awaitingConfirmation }

extension DemoVerificationStatusLabel on DemoVerificationStatus {
  String get label => switch (this) {
    DemoVerificationStatus.institutionConfirmed => 'Confirmed (demo only)',
    DemoVerificationStatus.awaitingConfirmation => 'Awaiting confirmation',
  };
}

enum DemoRequestStatus {
  awaitingVerification,
  coordinating,
  institutionConfirmed,
  closed,
}

extension DemoRequestStatusLabel on DemoRequestStatus {
  String get label => switch (this) {
    DemoRequestStatus.awaitingVerification => 'Pending verification',
    DemoRequestStatus.coordinating => 'In coordination',
    DemoRequestStatus.institutionConfirmed => 'Confirmed (demo)',
    DemoRequestStatus.closed => 'Closed (demo)',
  };

  bool get isActive => this != DemoRequestStatus.closed;
}

enum DemoResourceCategory { blood, icu, equipment }

extension DemoResourceCategoryLabel on DemoResourceCategory {
  String get label => switch (this) {
    DemoResourceCategory.blood => 'Blood components',
    DemoResourceCategory.icu => 'ICU & emergency beds',
    DemoResourceCategory.equipment => 'Medical equipment',
  };
}

class DemoHospitalNode {
  final String name;
  final String location;
  final DateTime lastUpdatedAt;
  final DemoVerificationStatus verification;

  const DemoHospitalNode({
    required this.name,
    required this.location,
    required this.lastUpdatedAt,
    required this.verification,
  });
}

class DemoResourceListing {
  final String name;
  final DemoResourceCategory category;
  final int listedQuantity;
  final String unit;
  final String hospitalName;
  final String location;
  final DateTime lastUpdatedAt;
  final DemoVerificationStatus verification;

  const DemoResourceListing({
    required this.name,
    required this.category,
    required this.listedQuantity,
    required this.unit,
    required this.hospitalName,
    required this.location,
    required this.lastUpdatedAt,
    required this.verification,
  });
}

class DemoCoordinationRequest {
  final String requestId;
  final String resourceCategory;
  final String requestingHospital;
  final String location;
  final DemoRequestStatus status;
  final DateTime lastUpdatedAt;
  final DemoVerificationStatus verification;

  const DemoCoordinationRequest({
    required this.requestId,
    required this.resourceCategory,
    required this.requestingHospital,
    required this.location,
    required this.status,
    required this.lastUpdatedAt,
    required this.verification,
  });
}

class DemoNetworkActivity {
  final String title;
  final String detail;
  final String hospitalName;
  final DateTime occurredAt;
  final DemoVerificationStatus verification;

  const DemoNetworkActivity({
    required this.title,
    required this.detail,
    required this.hospitalName,
    required this.occurredAt,
    required this.verification,
  });
}

class SyntheticDashboardData {
  SyntheticDashboardData._();

  static final _now = DateTime.now();

  static final hospitals = <DemoHospitalNode>[
    DemoHospitalNode(
      name: 'Northstar Teaching Hospital (Demo)',
      location: 'North District · Demo State',
      lastUpdatedAt: _now.subtract(const Duration(minutes: 8)),
      verification: DemoVerificationStatus.institutionConfirmed,
    ),
    DemoHospitalNode(
      name: 'Cedar Valley Medical Center (Demo)',
      location: 'Central District · Demo State',
      lastUpdatedAt: _now.subtract(const Duration(minutes: 24)),
      verification: DemoVerificationStatus.awaitingConfirmation,
    ),
    DemoHospitalNode(
      name: 'Riverside Regional Hospital (Demo)',
      location: 'East District · Demo State',
      lastUpdatedAt: _now.subtract(const Duration(hours: 1, minutes: 12)),
      verification: DemoVerificationStatus.institutionConfirmed,
    ),
    DemoHospitalNode(
      name: 'Meadowbrook Community Hospital (Demo)',
      location: 'South District · Demo State',
      lastUpdatedAt: _now.subtract(const Duration(hours: 3)),
      verification: DemoVerificationStatus.awaitingConfirmation,
    ),
    DemoHospitalNode(
      name: 'Summit Emergency Center (Demo)',
      location: 'West District · Demo State',
      lastUpdatedAt: _now.subtract(const Duration(days: 1, hours: 2)),
      verification: DemoVerificationStatus.institutionConfirmed,
    ),
    DemoHospitalNode(
      name: 'Lakeside Medical Institute (Demo)',
      location: 'Coastal District · Demo State',
      lastUpdatedAt: _now.subtract(const Duration(days: 2, hours: 4)),
      verification: DemoVerificationStatus.awaitingConfirmation,
    ),
  ];

  static final resources = <DemoResourceListing>[
    DemoResourceListing(
      name: 'Packed red blood cells',
      category: DemoResourceCategory.blood,
      listedQuantity: 24,
      unit: 'units',
      hospitalName: hospitals[0].name,
      location: hospitals[0].location,
      lastUpdatedAt: _now.subtract(const Duration(minutes: 32)),
      verification: DemoVerificationStatus.institutionConfirmed,
    ),
    DemoResourceListing(
      name: 'Platelet units',
      category: DemoResourceCategory.blood,
      listedQuantity: 11,
      unit: 'units',
      hospitalName: hospitals[2].name,
      location: hospitals[2].location,
      lastUpdatedAt: _now.subtract(const Duration(hours: 2)),
      verification: DemoVerificationStatus.awaitingConfirmation,
    ),
    DemoResourceListing(
      name: 'Fresh frozen plasma',
      category: DemoResourceCategory.blood,
      listedQuantity: 18,
      unit: 'units',
      hospitalName: hospitals[4].name,
      location: hospitals[4].location,
      lastUpdatedAt: _now.subtract(const Duration(hours: 5)),
      verification: DemoVerificationStatus.institutionConfirmed,
    ),
    DemoResourceListing(
      name: 'Adult ICU bed listings',
      category: DemoResourceCategory.icu,
      listedQuantity: 7,
      unit: 'beds',
      hospitalName: hospitals[1].name,
      location: hospitals[1].location,
      lastUpdatedAt: _now.subtract(const Duration(minutes: 48)),
      verification: DemoVerificationStatus.awaitingConfirmation,
    ),
    DemoResourceListing(
      name: 'Ventilator-supported ICU listings',
      category: DemoResourceCategory.icu,
      listedQuantity: 3,
      unit: 'beds',
      hospitalName: hospitals[3].name,
      location: hospitals[3].location,
      lastUpdatedAt: _now.subtract(const Duration(hours: 4)),
      verification: DemoVerificationStatus.institutionConfirmed,
    ),
    DemoResourceListing(
      name: 'Pediatric ICU bed listings',
      category: DemoResourceCategory.icu,
      listedQuantity: 2,
      unit: 'beds',
      hospitalName: hospitals[5].name,
      location: hospitals[5].location,
      lastUpdatedAt: _now.subtract(const Duration(days: 1)),
      verification: DemoVerificationStatus.awaitingConfirmation,
    ),
    DemoResourceListing(
      name: 'Ventilators',
      category: DemoResourceCategory.equipment,
      listedQuantity: 8,
      unit: 'devices',
      hospitalName: hospitals[0].name,
      location: hospitals[0].location,
      lastUpdatedAt: _now.subtract(const Duration(hours: 1)),
      verification: DemoVerificationStatus.institutionConfirmed,
    ),
    DemoResourceListing(
      name: 'Infusion pumps',
      category: DemoResourceCategory.equipment,
      listedQuantity: 5,
      unit: 'devices',
      hospitalName: hospitals[2].name,
      location: hospitals[2].location,
      lastUpdatedAt: _now.subtract(const Duration(hours: 6)),
      verification: DemoVerificationStatus.awaitingConfirmation,
    ),
    DemoResourceListing(
      name: 'Portable dialysis units',
      category: DemoResourceCategory.equipment,
      listedQuantity: 3,
      unit: 'devices',
      hospitalName: hospitals[4].name,
      location: hospitals[4].location,
      lastUpdatedAt: _now.subtract(const Duration(days: 1, hours: 3)),
      verification: DemoVerificationStatus.institutionConfirmed,
    ),
  ];

  static final requests = <DemoCoordinationRequest>[
    DemoCoordinationRequest(
      requestId: 'DEMO-REQ-101',
      resourceCategory: 'Blood components',
      requestingHospital: hospitals[1].name,
      location: hospitals[1].location,
      status: DemoRequestStatus.awaitingVerification,
      lastUpdatedAt: _now.subtract(const Duration(minutes: 18)),
      verification: DemoVerificationStatus.awaitingConfirmation,
    ),
    DemoCoordinationRequest(
      requestId: 'DEMO-REQ-102',
      resourceCategory: 'ICU & emergency beds',
      requestingHospital: hospitals[3].name,
      location: hospitals[3].location,
      status: DemoRequestStatus.coordinating,
      lastUpdatedAt: _now.subtract(const Duration(hours: 2)),
      verification: DemoVerificationStatus.awaitingConfirmation,
    ),
    DemoCoordinationRequest(
      requestId: 'DEMO-REQ-103',
      resourceCategory: 'Medical equipment',
      requestingHospital: hospitals[4].name,
      location: hospitals[4].location,
      status: DemoRequestStatus.institutionConfirmed,
      lastUpdatedAt: _now.subtract(const Duration(hours: 5)),
      verification: DemoVerificationStatus.institutionConfirmed,
    ),
    DemoCoordinationRequest(
      requestId: 'DEMO-REQ-104',
      resourceCategory: 'Organ & tissue coordination',
      requestingHospital: hospitals[0].name,
      location: hospitals[0].location,
      status: DemoRequestStatus.coordinating,
      lastUpdatedAt: _now.subtract(const Duration(days: 1, hours: 2)),
      verification: DemoVerificationStatus.institutionConfirmed,
    ),
    DemoCoordinationRequest(
      requestId: 'DEMO-REQ-105',
      resourceCategory: 'Blood components',
      requestingHospital: hospitals[2].name,
      location: hospitals[2].location,
      status: DemoRequestStatus.closed,
      lastUpdatedAt: _now.subtract(const Duration(days: 2)),
      verification: DemoVerificationStatus.institutionConfirmed,
    ),
    DemoCoordinationRequest(
      requestId: 'DEMO-REQ-106',
      resourceCategory: 'Medical equipment',
      requestingHospital: hospitals[5].name,
      location: hospitals[5].location,
      status: DemoRequestStatus.awaitingVerification,
      lastUpdatedAt: _now.subtract(const Duration(days: 4)),
      verification: DemoVerificationStatus.awaitingConfirmation,
    ),
    DemoCoordinationRequest(
      requestId: 'DEMO-REQ-107',
      resourceCategory: 'ICU & emergency beds',
      requestingHospital: hospitals[1].name,
      location: hospitals[1].location,
      status: DemoRequestStatus.coordinating,
      lastUpdatedAt: _now.subtract(const Duration(days: 9)),
      verification: DemoVerificationStatus.awaitingConfirmation,
    ),
    DemoCoordinationRequest(
      requestId: 'DEMO-REQ-108',
      resourceCategory: 'Blood components',
      requestingHospital: hospitals[4].name,
      location: hospitals[4].location,
      status: DemoRequestStatus.closed,
      lastUpdatedAt: _now.subtract(const Duration(days: 18)),
      verification: DemoVerificationStatus.institutionConfirmed,
    ),
  ];

  static final networkActivity = hospitals
      .map(
        (hospital) => DemoNetworkActivity(
          title: 'Synthetic network update',
          detail: hospital.location,
          hospitalName: hospital.name,
          occurredAt: hospital.lastUpdatedAt,
          verification: hospital.verification,
        ),
      )
      .toList();
}
