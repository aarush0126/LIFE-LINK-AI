import 'package:latlong2/latlong.dart';

enum DemoHospitalType {
  apexTeaching('Apex teaching centre'),
  regional('Regional hospital'),
  traumaBlood('Trauma & blood centre'),
  specialty('Specialty coordination centre');

  const DemoHospitalType(this.label);

  final String label;
}

enum DemoHospitalVerification {
  demoVerified('Demo-verified · illustrative'),
  pending('Verification pending'),
  reported('Reported · unverified');

  const DemoHospitalVerification(this.label);

  final String label;
}

class DemoHospital {
  final String name;
  final String institutionId;
  final String city;
  final String state;
  final DemoHospitalType type;
  final DemoHospitalVerification verification;
  final List<String> coordinationModules;
  final DateTime lastSynchronizedAt;
  final LatLng coordinates;
  final List<String> capabilities;

  const DemoHospital({
    required this.name,
    required this.institutionId,
    required this.city,
    required this.state,
    required this.type,
    required this.verification,
    required this.coordinationModules,
    required this.lastSynchronizedAt,
    required this.coordinates,
    required this.capabilities,
  });

  String get locationLabel => '$city, $state';

  bool supportsResource(String query) {
    final normalized = query.trim().toLowerCase();
    return normalized.isEmpty ||
        coordinationModules.any(
          (module) => module.toLowerCase().contains(normalized),
        ) ||
        capabilities.any(
          (capability) => capability.toLowerCase().contains(normalized),
        );
  }
}

class SyntheticHospitalNetworkData {
  SyntheticHospitalNetworkData._();

  static final _now = DateTime.now();

  static final hospitals = <DemoHospital>[
    DemoHospital(
      name: 'Northstar Institute of Connected Care (Demo)',
      institutionId: 'DEMO-HN-1001',
      city: 'New Delhi',
      state: 'Delhi',
      type: DemoHospitalType.apexTeaching,
      verification: DemoHospitalVerification.demoVerified,
      coordinationModules: const [
        'ICU & emergency beds',
        'Medical equipment',
        'Blood bank',
        'Organ & tissue coordination',
      ],
      lastSynchronizedAt: _now.subtract(const Duration(minutes: 14)),
      coordinates: const LatLng(28.6139, 77.2090),
      capabilities: const [
        'Critical care coordination desk',
        'Ventilator and patient-monitor enquiry',
        'Blood component enquiry',
        'Authorized transplant coordination liaison',
      ],
    ),
    DemoHospital(
      name: 'Cedar Valley Regional Medical Centre (Demo)',
      institutionId: 'DEMO-HN-1002',
      city: 'Chandigarh',
      state: 'Chandigarh',
      type: DemoHospitalType.regional,
      verification: DemoHospitalVerification.pending,
      coordinationModules: const [
        'ICU & emergency beds',
        'Medical equipment',
        'Blood bank',
      ],
      lastSynchronizedAt: _now.subtract(const Duration(hours: 1, minutes: 25)),
      coordinates: const LatLng(30.7333, 76.7794),
      capabilities: const [
        'Regional ICU enquiry coordination',
        'Dialysis equipment coordination',
        'Blood component enquiry desk',
      ],
    ),
    DemoHospital(
      name: 'Riverside Emergency & Blood Services (Demo)',
      institutionId: 'DEMO-HN-1003',
      city: 'Ludhiana',
      state: 'Punjab',
      type: DemoHospitalType.traumaBlood,
      verification: DemoHospitalVerification.reported,
      coordinationModules: const [
        'ICU & emergency beds',
        'Blood bank',
        'Medical equipment',
      ],
      lastSynchronizedAt: _now.subtract(const Duration(hours: 3)),
      coordinates: const LatLng(30.9010, 75.8573),
      capabilities: const [
        'Emergency capacity enquiry',
        'Blood bank coordination desk',
        'Oxygen delivery equipment enquiry',
      ],
    ),
    DemoHospital(
      name: 'Meadowbrook Clinical Coordination Centre (Demo)',
      institutionId: 'DEMO-HN-1004',
      city: 'Mumbai',
      state: 'Maharashtra',
      type: DemoHospitalType.specialty,
      verification: DemoHospitalVerification.demoVerified,
      coordinationModules: const [
        'Organ & tissue coordination',
        'ICU & emergency beds',
        'Medical equipment',
      ],
      lastSynchronizedAt: _now.subtract(const Duration(minutes: 42)),
      coordinates: const LatLng(19.0760, 72.8777),
      capabilities: const [
        'Authorized transplant coordination liaison',
        'Critical care enquiry desk',
        'Patient monitor and ventilator enquiry',
      ],
    ),
    DemoHospital(
      name: 'Summit South Regional Hospital (Demo)',
      institutionId: 'DEMO-HN-1005',
      city: 'Chennai',
      state: 'Tamil Nadu',
      type: DemoHospitalType.regional,
      verification: DemoHospitalVerification.demoVerified,
      coordinationModules: const [
        'ICU & emergency beds',
        'Blood bank',
        'Medical equipment',
      ],
      lastSynchronizedAt: _now.subtract(const Duration(minutes: 28)),
      coordinates: const LatLng(13.0827, 80.2707),
      capabilities: const [
        'Critical care enquiry desk',
        'Blood bank coordination',
        'Dialysis and patient monitor enquiry',
      ],
    ),
    DemoHospital(
      name: 'Bluewater Teaching Hospital (Demo)',
      institutionId: 'DEMO-HN-1006',
      city: 'Kolkata',
      state: 'West Bengal',
      type: DemoHospitalType.apexTeaching,
      verification: DemoHospitalVerification.pending,
      coordinationModules: const [
        'Organ & tissue coordination',
        'Blood bank',
        'ICU & emergency beds',
      ],
      lastSynchronizedAt: _now.subtract(const Duration(hours: 2, minutes: 10)),
      coordinates: const LatLng(22.5726, 88.3639),
      capabilities: const [
        'Teaching-centre coordination desk',
        'Blood component enquiry',
        'Authorized institutional transplant liaison',
      ],
    ),
    DemoHospital(
      name: 'Silverline Regional Health Network (Demo)',
      institutionId: 'DEMO-HN-1007',
      city: 'Bengaluru',
      state: 'Karnataka',
      type: DemoHospitalType.traumaBlood,
      verification: DemoHospitalVerification.reported,
      coordinationModules: const [
        'Blood bank',
        'Medical equipment',
        'ICU & emergency beds',
      ],
      lastSynchronizedAt: _now.subtract(const Duration(hours: 5, minutes: 35)),
      coordinates: const LatLng(12.9716, 77.5946),
      capabilities: const [
        'Regional emergency enquiry desk',
        'Blood bank coordination',
        'Ventilator availability enquiry',
      ],
    ),
    DemoHospital(
      name: 'Highland Specialty Care Centre (Demo)',
      institutionId: 'DEMO-HN-1008',
      city: 'Guwahati',
      state: 'Assam',
      type: DemoHospitalType.specialty,
      verification: DemoHospitalVerification.demoVerified,
      coordinationModules: const [
        'Medical equipment',
        'ICU & emergency beds',
        'Blood bank',
      ],
      lastSynchronizedAt: _now.subtract(const Duration(minutes: 55)),
      coordinates: const LatLng(26.1445, 91.7362),
      capabilities: const [
        'Regional critical-care enquiry desk',
        'Oxygen delivery equipment coordination',
        'Blood component enquiry',
      ],
    ),
    DemoHospital(
      name: 'Sunrise Regional Medical Centre (Demo)',
      institutionId: 'DEMO-HN-1009',
      city: 'Jaipur',
      state: 'Rajasthan',
      type: DemoHospitalType.regional,
      verification: DemoHospitalVerification.pending,
      coordinationModules: const [
        'ICU & emergency beds',
        'Medical equipment',
        'Organ & tissue coordination',
      ],
      lastSynchronizedAt: _now.subtract(const Duration(hours: 1, minutes: 48)),
      coordinates: const LatLng(26.9124, 75.7873),
      capabilities: const [
        'Regional bed enquiry coordination',
        'Patient monitor and dialysis enquiry',
        'Authorized transplant coordination liaison',
      ],
    ),
    DemoHospital(
      name: 'Coastal Care Network Hospital (Demo)',
      institutionId: 'DEMO-HN-1010',
      city: 'Kochi',
      state: 'Kerala',
      type: DemoHospitalType.traumaBlood,
      verification: DemoHospitalVerification.demoVerified,
      coordinationModules: const [
        'Blood bank',
        'ICU & emergency beds',
        'Medical equipment',
      ],
      lastSynchronizedAt: _now.subtract(const Duration(minutes: 36)),
      coordinates: const LatLng(9.9312, 76.2673),
      capabilities: const [
        'Emergency capacity enquiry desk',
        'Blood bank coordination',
        'Oxygen and ventilator enquiry',
      ],
    ),
  ];

  static List<String> get states =>
      hospitals.map((hospital) => hospital.state).toSet().toList()..sort();

  static List<String> citiesForState(String state) {
    final hospitalsForState = state == 'All states'
        ? hospitals
        : hospitals.where((hospital) => hospital.state == state);
    return hospitalsForState.map((hospital) => hospital.city).toSet().toList()
      ..sort();
  }
}
