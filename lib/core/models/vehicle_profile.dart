import 'insurance_profile.dart';
import 'model_utils.dart';
// model ymathel profil voiture fi app

class VehicleProfile {
  const VehicleProfile({
    required this.id,
    required this.userId,
    required this.plateNumber,
    required this.isPrimary,
    required this.verificationStatus,
    required this.createdAt,
    required this.updatedAt,
      // assurance linked bel voiture
    this.insuranceProfileId,
    this.vin,
    this.brand,
    this.model,
    this.firstRegistrationDate,
    this.registrationDocumentScanId,
    this.color,
  });

  final String id;
  final String userId;
  final String? insuranceProfileId;
  final String plateNumber;
  final String? vin;
  final String? brand;
  final String? model;
  final DateTime? firstRegistrationDate;
    // scan id mte3 carte grise
  final String? registrationDocumentScanId;
  final String? color;
  final bool isPrimary;
  final ProfileVerificationStatus verificationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  VehicleProfile copyWith({
    String? id,
    String? userId,
    Object? insuranceProfileId = unset,
    String? plateNumber,
    Object? vin = unset,
    Object? brand = unset,
    Object? model = unset,
    Object? firstRegistrationDate = unset,
    Object? registrationDocumentScanId = unset,
    Object? color = unset,
    bool? isPrimary,
    ProfileVerificationStatus? verificationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      insuranceProfileId: identical(insuranceProfileId, unset)
          ? this.insuranceProfileId
          : insuranceProfileId as String?,
      plateNumber: plateNumber ?? this.plateNumber,
      vin: identical(vin, unset) ? this.vin : vin as String?,
      brand: identical(brand, unset) ? this.brand : brand as String?,
      model: identical(model, unset) ? this.model : model as String?,
      firstRegistrationDate: identical(firstRegistrationDate, unset)
          ? this.firstRegistrationDate
          : firstRegistrationDate as DateTime?,
      registrationDocumentScanId: identical(registrationDocumentScanId, unset)
          ? this.registrationDocumentScanId
          : registrationDocumentScanId as String?,
      color: identical(color, unset) ? this.color : color as String?,
      isPrimary: isPrimary ?? this.isPrimary,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory VehicleProfile.fromJson(Map<String, dynamic> json) {
    return VehicleProfile(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      insuranceProfileId: json['insuranceProfileId'] as String?,
      plateNumber: json['plateNumber'] as String? ?? '',
      vin: json['vin'] as String?,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      firstRegistrationDate: dateTimeFromJson(json['firstRegistrationDate']),
      registrationDocumentScanId: json['registrationDocumentScanId'] as String?,
      color: json['color'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
      verificationStatus: ProfileVerificationStatus.fromValue(
        json['verificationStatus'] as String?,
      ),
      createdAt: dateTimeFromJson(json['createdAt']) ?? DateTime.now(),
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'insuranceProfileId': insuranceProfileId,
      'plateNumber': plateNumber,
      'vin': vin,
      'brand': brand,
      'model': model,
      'firstRegistrationDate': firstRegistrationDate?.toIso8601String(),
      'registrationDocumentScanId': registrationDocumentScanId,
      'color': color,
      'isPrimary': isPrimary,
      'verificationStatus': verificationStatus.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
