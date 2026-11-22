enum BloodStockStatus {
  critical,
  low,
  optimal,
  surplus,
}

class BloodGroupInventory {
  final String bloodGroup; // A+, A-, B+, B-, AB+, AB-, O+, O-
  final int wholeBloodUnits;
  final int packedRedBloodCells;
  final int plateletsUnits;
  final int freshFrozenPlasma;
  final int safetyThreshold;

  const BloodGroupInventory({
    required this.bloodGroup,
    required this.wholeBloodUnits,
    required this.packedRedBloodCells,
    required this.plateletsUnits,
    required this.freshFrozenPlasma,
    required this.safetyThreshold,
  });

  int get totalUnits =>
      wholeBloodUnits + packedRedBloodCells + plateletsUnits + freshFrozenPlasma;

  BloodStockStatus get status {
    if (totalUnits <= safetyThreshold * 0.4) {
      return BloodStockStatus.critical;
    } else if (totalUnits <= safetyThreshold) {
      return BloodStockStatus.low;
    } else if (totalUnits > safetyThreshold * 2.5) {
      return BloodStockStatus.surplus;
    }
    return BloodStockStatus.optimal;
  }

  factory BloodGroupInventory.fromJson(Map<String, dynamic> json) {
    return BloodGroupInventory(
      bloodGroup: json['bloodGroup'] as String,
      wholeBloodUnits: json['wholeBloodUnits'] as int,
      packedRedBloodCells: json['packedRedBloodCells'] as int,
      plateletsUnits: json['plateletsUnits'] as int,
      freshFrozenPlasma: json['freshFrozenPlasma'] as int,
      safetyThreshold: json['safetyThreshold'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bloodGroup': bloodGroup,
      'wholeBloodUnits': wholeBloodUnits,
      'packedRedBloodCells': packedRedBloodCells,
      'plateletsUnits': plateletsUnits,
      'freshFrozenPlasma': freshFrozenPlasma,
      'safetyThreshold': safetyThreshold,
    };
  }
}
