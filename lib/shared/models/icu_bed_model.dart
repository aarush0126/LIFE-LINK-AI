enum BedStatus {
  available,
  occupied,
  reservedEmergency,
  maintenance,
}

enum BedCategory {
  medicalIcu,
  surgicalIcu,
  cardiacIcu,
  pediatricIcu,
  neonatalIcu,
  traumaIcu,
}

class IcuBedModel {
  final String id;
  final String hospitalId;
  final String hospitalName;
  final String bedCode; // e.g. MICU-04
  final BedCategory category;
  final BedStatus status;
  final bool hasDedicatedVentilator;
  final bool hasEcmoSupport;
  final bool hasNegativePressureIsolation;
  final String? patientId;
  final DateTime? admittedAt;

  const IcuBedModel({
    required this.id,
    required this.hospitalId,
    required this.hospitalName,
    required this.bedCode,
    required this.category,
    required this.status,
    required this.hasDedicatedVentilator,
    required this.hasEcmoSupport,
    required this.hasNegativePressureIsolation,
    this.patientId,
    this.admittedAt,
  });

  factory IcuBedModel.fromJson(Map<String, dynamic> json) {
    return IcuBedModel(
      id: json['id'] as String,
      hospitalId: json['hospitalId'] as String,
      hospitalName: json['hospitalName'] as String,
      bedCode: json['bedCode'] as String,
      category: BedCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => BedCategory.medicalIcu,
      ),
      status: BedStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BedStatus.available,
      ),
      hasDedicatedVentilator: json['hasDedicatedVentilator'] as bool? ?? false,
      hasEcmoSupport: json['hasEcmoSupport'] as bool? ?? false,
      hasNegativePressureIsolation: json['hasNegativePressureIsolation'] as bool? ?? false,
      patientId: json['patientId'] as String?,
      admittedAt: json['admittedAt'] != null ? DateTime.parse(json['admittedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'bedCode': bedCode,
      'category': category.name,
      'status': status.name,
      'hasDedicatedVentilator': hasDedicatedVentilator,
      'hasEcmoSupport': hasEcmoSupport,
      'hasNegativePressureIsolation': hasNegativePressureIsolation,
      'patientId': patientId,
      'admittedAt': admittedAt?.toIso8601String(),
    };
  }
}
