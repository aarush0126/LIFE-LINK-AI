enum EquipmentStatus {
  operational,
  inUse,
  scheduledMaintenance,
  offlineFault,
}

class EquipmentModel {
  final String id;
  final String name;
  final String serialNumber;
  final String type; // Ventilator, ECMO, Dialysis, BiPAP, Multipara Monitor
  final String hospitalId;
  final String hospitalName;
  final String wardLocation;
  final EquipmentStatus status;
  final int operationalHours;
  final DateTime lastInspectedAt;

  const EquipmentModel({
    required this.id,
    required this.name,
    required this.serialNumber,
    required this.type,
    required this.hospitalId,
    required this.hospitalName,
    required this.wardLocation,
    required this.status,
    required this.operationalHours,
    required this.lastInspectedAt,
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      serialNumber: json['serialNumber'] as String,
      type: json['type'] as String,
      hospitalId: json['hospitalId'] as String,
      hospitalName: json['hospitalName'] as String,
      wardLocation: json['wardLocation'] as String,
      status: EquipmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => EquipmentStatus.operational,
      ),
      operationalHours: json['operationalHours'] as int,
      lastInspectedAt: DateTime.parse(json['lastInspectedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'serialNumber': serialNumber,
      'type': type,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'wardLocation': wardLocation,
      'status': status.name,
      'operationalHours': operationalHours,
      'lastInspectedAt': lastInspectedAt.toIso8601String(),
    };
  }
}
