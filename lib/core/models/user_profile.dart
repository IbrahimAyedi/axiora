import 'model_utils.dart';
// model ymathel profil user fi app

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.isEmailVerified,
    required this.createdAt,
    required this.updatedAt,
    this.fullName,
    this.phoneNumber,
    this.insuranceNumber,
    this.preferredLanguage,
    this.mainInsuranceProfileId,
    this.mainVehicleProfileId,
    this.mainDriverProfileId,
    this.role,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? insuranceNumber;
  final String? preferredLanguage;
  final bool isEmailVerified;
  final String? mainInsuranceProfileId;
  final String? mainVehicleProfileId;
  final String? mainDriverProfileId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // true ken user admin
  final String? role;

  bool get isAdmin => role == 'admin';
  // copyWith ya3mel copie jdida m3a changement mte3 fields mou3ayna

  UserProfile copyWith({
    String? id,
    String? email,
    Object? fullName = unset,
    Object? phoneNumber = unset,
    Object? insuranceNumber = unset,
    Object? preferredLanguage = unset,
    bool? isEmailVerified,
    Object? mainInsuranceProfileId = unset,
    Object? mainVehicleProfileId = unset,
    Object? mainDriverProfileId = unset,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? role = unset,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: identical(fullName, unset)
          ? this.fullName
          : fullName as String?,
      phoneNumber: identical(phoneNumber, unset)
          ? this.phoneNumber
          : phoneNumber as String?,
      insuranceNumber: identical(insuranceNumber, unset)
          ? this.insuranceNumber
          : insuranceNumber as String?,
      preferredLanguage: identical(preferredLanguage, unset)
          ? this.preferredLanguage
          : preferredLanguage as String?,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      mainInsuranceProfileId: identical(mainInsuranceProfileId, unset)
          ? this.mainInsuranceProfileId
          : mainInsuranceProfileId as String?,
      mainVehicleProfileId: identical(mainVehicleProfileId, unset)
          ? this.mainVehicleProfileId
          : mainVehicleProfileId as String?,
      mainDriverProfileId: identical(mainDriverProfileId, unset)
          ? this.mainDriverProfileId
          : mainDriverProfileId as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: identical(role, unset) ? this.role : role as String?,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      insuranceNumber: json['insuranceNumber'] as String?,
      preferredLanguage: json['preferredLanguage'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      mainInsuranceProfileId: json['mainInsuranceProfileId'] as String?,
      mainVehicleProfileId: json['mainVehicleProfileId'] as String?,
      mainDriverProfileId: json['mainDriverProfileId'] as String?,
      createdAt: dateTimeFromJson(json['createdAt']) ?? DateTime.now(),
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? DateTime.now(),
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'insuranceNumber': insuranceNumber,
      'preferredLanguage': preferredLanguage,
      'isEmailVerified': isEmailVerified,
      'mainInsuranceProfileId': mainInsuranceProfileId,
      'mainVehicleProfileId': mainVehicleProfileId,
      'mainDriverProfileId': mainDriverProfileId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'role': role,
    };
  }
}
