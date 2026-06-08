import 'insurance_profile.dart';
import 'model_utils.dart';
// model ymathel profil conducteur fi app

class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.isPrimary,
    required this.verificationStatus,
    required this.createdAt,
    required this.updatedAt,
    this.licenseNumber,
    this.nationalId,
    this.dateOfBirth,
    this.licenseIssueDate,
    this.licenseExpiryDate,
    this.licenseCategory,
    this.driverDocumentScanId,
    this.phoneNumber,
    this.address,
  });
  // basic driver info
  final String id;
  final String userId;
  final String fullName;
    // permis w identity info

  final String? licenseNumber;
  final String? nationalId;
  final DateTime? dateOfBirth;
  final DateTime? licenseIssueDate;
  final DateTime? licenseExpiryDate;
  final String? licenseCategory;
    // scan id mte3 permis
  final String? driverDocumentScanId;
  final String? phoneNumber;
  final String? address;
    // true ken howa conducteur principal
  final bool isPrimary;
  final ProfileVerificationStatus verificationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverProfile copyWith({
    String? id,
    String? userId,
    String? fullName,
    Object? licenseNumber = unset,
    Object? nationalId = unset,
    Object? dateOfBirth = unset,
    Object? licenseIssueDate = unset,
    Object? licenseExpiryDate = unset,
    Object? licenseCategory = unset,
    Object? driverDocumentScanId = unset,
    Object? phoneNumber = unset,
    Object? address = unset,
    bool? isPrimary,
    ProfileVerificationStatus? verificationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      licenseNumber: identical(licenseNumber, unset)
          ? this.licenseNumber
          : licenseNumber as String?,
      nationalId: identical(nationalId, unset)
          ? this.nationalId
          : nationalId as String?,
      dateOfBirth: identical(dateOfBirth, unset)
          ? this.dateOfBirth
          : dateOfBirth as DateTime?,
      licenseIssueDate: identical(licenseIssueDate, unset)
          ? this.licenseIssueDate
          : licenseIssueDate as DateTime?,
      licenseExpiryDate: identical(licenseExpiryDate, unset)
          ? this.licenseExpiryDate
          : licenseExpiryDate as DateTime?,
      licenseCategory: identical(licenseCategory, unset)
          ? this.licenseCategory
          : licenseCategory as String?,
      driverDocumentScanId: identical(driverDocumentScanId, unset)
          ? this.driverDocumentScanId
          : driverDocumentScanId as String?,
      phoneNumber: identical(phoneNumber, unset)
          ? this.phoneNumber
          : phoneNumber as String?,
      address: identical(address, unset) ? this.address : address as String?,
      isPrimary: isPrimary ?? this.isPrimary,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  // fromJson t7awel data jeya mel Firestore l DriverProfile
  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      licenseNumber: json['licenseNumber'] as String?,
      nationalId: json['nationalId'] as String?,
      dateOfBirth: dateTimeFromJson(json['dateOfBirth']),
      licenseIssueDate: dateTimeFromJson(json['licenseIssueDate']),
      licenseExpiryDate: dateTimeFromJson(json['licenseExpiryDate']),
      licenseCategory: json['licenseCategory'] as String?,
      driverDocumentScanId: json['driverDocumentScanId'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
      verificationStatus: ProfileVerificationStatus.fromValue(
        json['verificationStatus'] as String?,
      ),
      createdAt: dateTimeFromJson(json['createdAt']) ?? DateTime.now(),
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? DateTime.now(),
    );
  }
  // toJson t7awel DriverProfile l Map bech yetkhazen fi Firestore

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'licenseNumber': licenseNumber,
      'nationalId': nationalId,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'licenseIssueDate': licenseIssueDate?.toIso8601String(),
      'licenseExpiryDate': licenseExpiryDate?.toIso8601String(),
      'licenseCategory': licenseCategory,
      'driverDocumentScanId': driverDocumentScanId,
      'phoneNumber': phoneNumber,
      'address': address,
      'isPrimary': isPrimary,
      'verificationStatus': verificationStatus.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
