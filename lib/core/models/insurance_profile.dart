import 'model_utils.dart';
// status mte3 profile verification
enum ProfileVerificationStatus {
  unverified,
  extracted,
  confirmed;

  String get value => name;

  static ProfileVerificationStatus fromValue(String? value) {
    return ProfileVerificationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ProfileVerificationStatus.unverified,
    );
  }
}

class InsuranceProfile {
  const InsuranceProfile({
    required this.id,
    required this.userId,
    required this.insuranceNumber,
    required this.companyName,
    required this.isPrimary,
    required this.verificationStatus,
    required this.createdAt,
    required this.updatedAt,
    this.policyHolderName,
    this.policyType,
    this.startDate,
    this.endDate,
    this.documentScanId,
  });

  final String id;
  final String userId;
  final String insuranceNumber;
  final String companyName;
  final String? policyHolderName;
  final String? policyType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? documentScanId;
  final bool isPrimary;
  final ProfileVerificationStatus verificationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  InsuranceProfile copyWith({
    String? id,
    String? userId,
    String? insuranceNumber,
    String? companyName,
    Object? policyHolderName = unset,
    Object? policyType = unset,
    Object? startDate = unset,
    Object? endDate = unset,
    Object? documentScanId = unset,
    bool? isPrimary,
    ProfileVerificationStatus? verificationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InsuranceProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      companyName: companyName ?? this.companyName,
      policyHolderName: identical(policyHolderName, unset)
          ? this.policyHolderName
          : policyHolderName as String?,
      policyType: identical(policyType, unset)
          ? this.policyType
          : policyType as String?,
      startDate: identical(startDate, unset)
          ? this.startDate
          : startDate as DateTime?,
      endDate: identical(endDate, unset) ? this.endDate : endDate as DateTime?,
      documentScanId: identical(documentScanId, unset)
          ? this.documentScanId
          : documentScanId as String?,
      isPrimary: isPrimary ?? this.isPrimary,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory InsuranceProfile.fromJson(Map<String, dynamic> json) {
    return InsuranceProfile(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      insuranceNumber: json['insuranceNumber'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      policyHolderName: json['policyHolderName'] as String?,
      policyType: json['policyType'] as String?,
      startDate: dateTimeFromJson(json['startDate']),
      endDate: dateTimeFromJson(json['endDate']),
      documentScanId: json['documentScanId'] as String?,
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
      'insuranceNumber': insuranceNumber,
      'companyName': companyName,
      'policyHolderName': policyHolderName,
      'policyType': policyType,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'documentScanId': documentScanId,
      'isPrimary': isPrimary,
      'verificationStatus': verificationStatus.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
