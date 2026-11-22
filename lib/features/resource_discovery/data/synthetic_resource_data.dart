enum DemoResourceVerification {
  reported('Reported · unverified'),
  awaitingConfirmation('Verification pending'),
  demoConfirmed('Demo-confirmed only');

  const DemoResourceVerification(this.label);

  final String label;
}

enum DemoBedCategory {
  icu('ICU'),
  general('General'),
  emergency('Emergency');

  const DemoBedCategory(this.label);

  final String label;
}

enum DemoBedUrgency {
  routine('Routine'),
  urgent('Urgent'),
  emergency('Emergency');

  const DemoBedUrgency(this.label);

  final String label;
}

enum DemoEquipmentCategory {
  ventilators('Ventilators'),
  dialysisMachines('Dialysis machines'),
  oxygenDelivery('Oxygen delivery equipment'),
  patientMonitors('Patient monitors'),
  otherCritical('Other critical equipment');

  const DemoEquipmentCategory(this.label);

  final String label;
}

enum DemoEquipmentStatus {
  available('Available'),
  inUse('In Use'),
  underMaintenance('Under Maintenance'),
  requiresConfirmation('Requires Confirmation');

  const DemoEquipmentStatus(this.label);

  final String label;
}

class DemoResourceHospital {
  final String name;
  final String location;

  const DemoResourceHospital({required this.name, required this.location});
}

class DemoBedListing {
  final String hospital;
  final String location;
  final DemoBedCategory category;
  final int totalCapacity;
  final int reportedOpenBeds;
  final DateTime lastUpdatedAt;
  final DemoResourceVerification verification;

  const DemoBedListing({
    required this.hospital,
    required this.location,
    required this.category,
    required this.totalCapacity,
    required this.reportedOpenBeds,
    required this.lastUpdatedAt,
    required this.verification,
  });
}

class DemoEquipmentRecord {
  final String equipmentId;
  final String hospital;
  final String location;
  final DemoEquipmentCategory category;
  final DemoEquipmentStatus status;
  final int quantity;
  final DateTime lastUpdatedAt;
  final DemoResourceVerification verification;

  const DemoEquipmentRecord({
    required this.equipmentId,
    required this.hospital,
    required this.location,
    required this.category,
    required this.status,
    required this.quantity,
    required this.lastUpdatedAt,
    required this.verification,
  });
}

class SyntheticResourceData {
  SyntheticResourceData._();

  static const hospitals = [
    DemoResourceHospital(
      name: 'Northstar Teaching Hospital (Demo)',
      location: 'North District · Demo State',
    ),
    DemoResourceHospital(
      name: 'Cedar Valley Medical Center (Demo)',
      location: 'Central District · Demo State',
    ),
    DemoResourceHospital(
      name: 'Riverside Regional Hospital (Demo)',
      location: 'East District · Demo State',
    ),
    DemoResourceHospital(
      name: 'Meadowbrook Community Hospital (Demo)',
      location: 'South District · Demo State',
    ),
  ];

  static const locations = [
    'North District · Demo State',
    'Central District · Demo State',
    'East District · Demo State',
    'South District · Demo State',
  ];

  static final _referenceTime = DateTime.now();

  static const _bedCapacities = [
    [60, 120, 20],
    [42, 100, 18],
    [36, 90, 16],
    [28, 80, 14],
  ];

  static const _reportedOpenBeds = [
    [8, 24, 5],
    [4, 17, 3],
    [6, 12, 4],
    [3, 19, 2],
  ];

  static final bedListings = [
    for (
      var hospitalIndex = 0;
      hospitalIndex < hospitals.length;
      hospitalIndex++
    )
      for (
        var categoryIndex = 0;
        categoryIndex < DemoBedCategory.values.length;
        categoryIndex++
      )
        _bedListing(hospitalIndex, categoryIndex),
  ];

  static final equipmentRecords = [
    for (
      var hospitalIndex = 0;
      hospitalIndex < hospitals.length;
      hospitalIndex++
    )
      for (
        var categoryIndex = 0;
        categoryIndex < DemoEquipmentCategory.values.length;
        categoryIndex++
      )
        _equipmentRecord(hospitalIndex, categoryIndex),
  ];

  static DemoBedListing _bedListing(int hospitalIndex, int categoryIndex) {
    final hospital = hospitals[hospitalIndex];
    final index = hospitalIndex * DemoBedCategory.values.length + categoryIndex;
    return DemoBedListing(
      hospital: hospital.name,
      location: hospital.location,
      category: DemoBedCategory.values[categoryIndex],
      totalCapacity: _bedCapacities[hospitalIndex][categoryIndex],
      reportedOpenBeds: _reportedOpenBeds[hospitalIndex][categoryIndex],
      lastUpdatedAt: _referenceTime.subtract(Duration(minutes: 8 + index * 19)),
      verification: DemoResourceVerification.values[index % 3],
    );
  }

  static DemoEquipmentRecord _equipmentRecord(
    int hospitalIndex,
    int categoryIndex,
  ) {
    final hospital = hospitals[hospitalIndex];
    final index =
        hospitalIndex * DemoEquipmentCategory.values.length + categoryIndex;
    return DemoEquipmentRecord(
      equipmentId: 'DEMO-EQ-${(index + 1).toString().padLeft(3, '0')}',
      hospital: hospital.name,
      location: hospital.location,
      category: DemoEquipmentCategory.values[categoryIndex],
      status: DemoEquipmentStatus.values[index % 4],
      quantity: 1 + ((hospitalIndex * 3 + categoryIndex * 2) % 8),
      lastUpdatedAt: _referenceTime.subtract(
        Duration(minutes: 12 + index * 16),
      ),
      verification: DemoResourceVerification.values[index % 3],
    );
  }
}
