enum OrganType {
  heart,
  lungs,
  liver,
  kidneyLeft,
  kidneyRight,
  pancreas,
  cornea,
}

enum AllocationStatus {
  evaluating,
  matched,
  transitEnRoute,
  greenCorridorActive,
  transplanted,
  expired,
}

class OrganDonationModel {
  final String id;
  final OrganType organType;
  final String bloodGroup;
  final String donorHospitalId;
  final String donorHospitalName;
  final String? recipientHospitalId;
  final String? recipientHospitalName;
  final AllocationStatus status;
  final double hlaCompatibilityScore; // 0.0 to 1.0
  final DateTime retrievalTime;
  final Duration maxIschemicTime;
  final bool isGreenCorridorActive;
  final String? corridorEscortUnit;

  const OrganDonationModel({
    required this.id,
    required this.organType,
    required this.bloodGroup,
    required this.donorHospitalId,
    required this.donorHospitalName,
    this.recipientHospitalId,
    this.recipientHospitalName,
    required this.status,
    required this.hlaCompatibilityScore,
    required this.retrievalTime,
    required this.maxIschemicTime,
    this.isGreenCorridorActive = false,
    this.corridorEscortUnit,
  });

  Duration get remainingIschemicTime {
    final elapsed = DateTime.now().difference(retrievalTime);
    final remaining = maxIschemicTime - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isCritical => remainingIschemicTime.inHours <= 2;

  factory OrganDonationModel.fromJson(Map<String, dynamic> json) {
    return OrganDonationModel(
      id: json['id'] as String,
      organType: OrganType.values.firstWhere(
        (e) => e.name == json['organType'],
        orElse: () => OrganType.kidneyLeft,
      ),
      bloodGroup: json['bloodGroup'] as String,
      donorHospitalId: json['donorHospitalId'] as String,
      donorHospitalName: json['donorHospitalName'] as String,
      recipientHospitalId: json['recipientHospitalId'] as String?,
      recipientHospitalName: json['recipientHospitalName'] as String?,
      status: AllocationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AllocationStatus.evaluating,
      ),
      hlaCompatibilityScore: (json['hlaCompatibilityScore'] as num).toDouble(),
      retrievalTime: DateTime.parse(json['retrievalTime'] as String),
      maxIschemicTime: Duration(minutes: json['maxIschemicMinutes'] as int),
      isGreenCorridorActive: json['isGreenCorridorActive'] as bool? ?? false,
      corridorEscortUnit: json['corridorEscortUnit'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organType': organType.name,
      'bloodGroup': bloodGroup,
      'donorHospitalId': donorHospitalId,
      'donorHospitalName': donorHospitalName,
      'recipientHospitalId': recipientHospitalId,
      'recipientHospitalName': recipientHospitalName,
      'status': status.name,
      'hlaCompatibilityScore': hlaCompatibilityScore,
      'retrievalTime': retrievalTime.toIso8601String(),
      'maxIschemicMinutes': maxIschemicTime.inMinutes,
      'isGreenCorridorActive': isGreenCorridorActive,
      'corridorEscortUnit': corridorEscortUnit,
    };
  }
}
