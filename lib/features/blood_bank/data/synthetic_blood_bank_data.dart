enum DemoBloodComponent {
  wholeBlood('Whole Blood'),
  packedRedBloodCells('Packed Red Blood Cells'),
  platelets('Platelets'),
  freshFrozenPlasma('Fresh Frozen Plasma');

  const DemoBloodComponent(this.label);

  final String label;
}

enum DemoBloodQuantityBand {
  underTen('1–9 units'),
  tenToTwentyFour('10–24 units'),
  twentyFiveOrMore('25+ units');

  const DemoBloodQuantityBand(this.label);

  final String label;
}

enum DemoBloodExpiryWindow {
  withinThreeDays('1–3 days'),
  withinSevenDays('4–7 days'),
  beyondSevenDays('More than 7 days');

  const DemoBloodExpiryWindow(this.label);

  final String label;
}

enum DemoBloodVerification {
  reported('Reported · unverified'),
  pending('Verification pending'),
  demoConfirmed('Demo-confirmed only');

  const DemoBloodVerification(this.label);

  final String label;
}

enum DemoBloodUrgency {
  routine('Routine'),
  urgent('Urgent'),
  emergency('Emergency');

  const DemoBloodUrgency(this.label);

  final String label;
}

enum DemoBloodRequestStatus {
  enquiryLogged('Enquiry logged · demo'),
  awaitingDemoResponse('Awaiting demo response'),
  syntheticResponse('Synthetic response recorded'),
  closedForDemo('Closed for demonstration');

  const DemoBloodRequestStatus(this.label);

  final String label;
}

class DemoBloodInventoryListing {
  final String hospital;
  final String location;
  final String bloodGroup;
  final DemoBloodComponent component;
  final int reportedUnits;
  final DateTime expiresAt;
  final int daysToExpiry;
  final DateTime lastUpdatedAt;
  final DemoBloodVerification verification;

  const DemoBloodInventoryListing({
    required this.hospital,
    required this.location,
    required this.bloodGroup,
    required this.component,
    required this.reportedUnits,
    required this.expiresAt,
    required this.daysToExpiry,
    required this.lastUpdatedAt,
    required this.verification,
  });

  DemoBloodQuantityBand get quantityBand => switch (reportedUnits) {
    < 10 => DemoBloodQuantityBand.underTen,
    < 25 => DemoBloodQuantityBand.tenToTwentyFour,
    _ => DemoBloodQuantityBand.twentyFiveOrMore,
  };

  DemoBloodExpiryWindow get expiryWindow => switch (daysToExpiry) {
    <= 3 => DemoBloodExpiryWindow.withinThreeDays,
    <= 7 => DemoBloodExpiryWindow.withinSevenDays,
    _ => DemoBloodExpiryWindow.beyondSevenDays,
  };
}

class DemoBloodRequest {
  final String requestId;
  final String requestingHospital;
  final String bloodGroup;
  final DemoBloodComponent component;
  final int requiredQuantity;
  final DemoBloodUrgency urgency;
  final String contactCoordinator;
  final DemoBloodRequestStatus status;
  final DateTime lastUpdatedAt;

  const DemoBloodRequest({
    required this.requestId,
    required this.requestingHospital,
    required this.bloodGroup,
    required this.component,
    required this.requiredQuantity,
    required this.urgency,
    required this.contactCoordinator,
    required this.status,
    required this.lastUpdatedAt,
  });
}

class DemoBloodNotification {
  final String title;
  final String detail;
  final String hospital;
  final DateTime occurredAt;
  final String requestId;

  const DemoBloodNotification({
    required this.title,
    required this.detail,
    required this.hospital,
    required this.occurredAt,
    required this.requestId,
  });
}

class SyntheticBloodBankData {
  SyntheticBloodBankData._();

  static const bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  static const hospitals = [
    'Northstar Teaching Hospital (Demo)',
    'Cedar Valley Medical Center (Demo)',
    'Riverside Regional Hospital (Demo)',
    'Meadowbrook Community Hospital (Demo)',
  ];

  static const locations = [
    'North District · Demo State',
    'Central District · Demo State',
    'East District · Demo State',
    'South District · Demo State',
  ];

  static final _referenceTime = DateTime.now();

  static final inventory = [
    for (var groupIndex = 0; groupIndex < bloodGroups.length; groupIndex++)
      for (
        var componentIndex = 0;
        componentIndex < DemoBloodComponent.values.length;
        componentIndex++
      )
        _listing(groupIndex, componentIndex),
  ];

  static final initialRequests = [
    _request(
      requestId: 'DEMO-BR-2101',
      hospitalIndex: 1,
      bloodGroup: 'O+',
      component: DemoBloodComponent.packedRedBloodCells,
      quantity: 6,
      urgency: DemoBloodUrgency.urgent,
      status: DemoBloodRequestStatus.awaitingDemoResponse,
      age: const Duration(minutes: 18),
    ),
    _request(
      requestId: 'DEMO-BR-2102',
      hospitalIndex: 2,
      bloodGroup: 'A-',
      component: DemoBloodComponent.platelets,
      quantity: 3,
      urgency: DemoBloodUrgency.routine,
      status: DemoBloodRequestStatus.syntheticResponse,
      age: const Duration(hours: 2),
    ),
    _request(
      requestId: 'DEMO-BR-2103',
      hospitalIndex: 0,
      bloodGroup: 'B+',
      component: DemoBloodComponent.freshFrozenPlasma,
      quantity: 4,
      urgency: DemoBloodUrgency.emergency,
      status: DemoBloodRequestStatus.closedForDemo,
      age: const Duration(hours: 7),
    ),
  ];

  static final initialNotifications = [
    DemoBloodNotification(
      title: 'Synthetic enquiry received',
      detail: 'A local demonstration request is awaiting a demo-only response. No external message was sent.',
      hospital: hospitals[1],
      occurredAt: _referenceTime.subtract(const Duration(minutes: 18)),
      requestId: 'DEMO-BR-2101',
    ),
    DemoBloodNotification(
      title: 'Demo response recorded',
      detail: 'Synthetic status event only. This is not a real stock confirmation or reservation.',
      hospital: hospitals[2],
      occurredAt: _referenceTime.subtract(const Duration(hours: 2)),
      requestId: 'DEMO-BR-2102',
    ),
  ];

  static DemoBloodInventoryListing _listing(
    int groupIndex,
    int componentIndex,
  ) {
    final index =
        groupIndex * DemoBloodComponent.values.length + componentIndex;
    final hospitalIndex = (groupIndex + componentIndex) % hospitals.length;
    final daysToExpiry = 1 + ((groupIndex * 5 + componentIndex * 3) % 18);

    return DemoBloodInventoryListing(
      hospital: hospitals[hospitalIndex],
      location: locations[hospitalIndex],
      bloodGroup: bloodGroups[groupIndex],
      component: DemoBloodComponent.values[componentIndex],
      reportedUnits: 8 + ((groupIndex * 11 + componentIndex * 7) % 39),
      expiresAt: _referenceTime.add(Duration(days: daysToExpiry)),
      daysToExpiry: daysToExpiry,
      lastUpdatedAt: _referenceTime.subtract(Duration(minutes: 9 + index * 13)),
      verification: DemoBloodVerification.values[index % 3],
    );
  }

  static DemoBloodRequest _request({
    required String requestId,
    required int hospitalIndex,
    required String bloodGroup,
    required DemoBloodComponent component,
    required int quantity,
    required DemoBloodUrgency urgency,
    required DemoBloodRequestStatus status,
    required Duration age,
  }) {
    return DemoBloodRequest(
      requestId: requestId,
      requestingHospital: hospitals[hospitalIndex],
      bloodGroup: bloodGroup,
      component: component,
      requiredQuantity: quantity,
      urgency: urgency,
      contactCoordinator: 'Demo coordinator ${hospitalIndex + 1}',
      status: status,
      lastUpdatedAt: _referenceTime.subtract(age),
    );
  }
}
