class HospitalModel {
  final String id;
  final String name;
  final String code; // Registry Code e.g. AIIMS-NDLS-01
  final String city;
  final String state;
  final String tier; // Tier-1 Apex, Tier-2 Regional, Tier-3 District
  final String contactNumber;
  final double latitude;
  final double longitude;
  final int totalIcuBeds;
  final int availableIcuBeds;
  final bool hasOrganRetrievalCenter;
  final bool hasOrganTransplantUnit;
  final bool hasLevel1Trauma;
  final double bloodReserveIndex; // 0.0 to 1.0

  const HospitalModel({
    required this.id,
    required this.name,
    required this.code,
    required this.city,
    required this.state,
    required this.tier,
    required this.contactNumber,
    required this.latitude,
    required this.longitude,
    required this.totalIcuBeds,
    required this.availableIcuBeds,
    required this.hasOrganRetrievalCenter,
    required this.hasOrganTransplantUnit,
    required this.hasLevel1Trauma,
    required this.bloodReserveIndex,
  });

  double get icuOccupancyRate =>
      totalIcuBeds > 0 ? (totalIcuBeds - availableIcuBeds) / totalIcuBeds : 0.0;

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      tier: json['tier'] as String,
      contactNumber: json['contactNumber'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      totalIcuBeds: json['totalIcuBeds'] as int,
      availableIcuBeds: json['availableIcuBeds'] as int,
      hasOrganRetrievalCenter: json['hasOrganRetrievalCenter'] as bool? ?? false,
      hasOrganTransplantUnit: json['hasOrganTransplantUnit'] as bool? ?? false,
      hasLevel1Trauma: json['hasLevel1Trauma'] as bool? ?? false,
      bloodReserveIndex: (json['bloodReserveIndex'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'city': city,
      'state': state,
      'tier': tier,
      'contactNumber': contactNumber,
      'latitude': latitude,
      'longitude': longitude,
      'totalIcuBeds': totalIcuBeds,
      'availableIcuBeds': availableIcuBeds,
      'hasOrganRetrievalCenter': hasOrganRetrievalCenter,
      'hasOrganTransplantUnit': hasOrganTransplantUnit,
      'hasLevel1Trauma': hasLevel1Trauma,
      'bloodReserveIndex': bloodReserveIndex,
    };
  }
}
