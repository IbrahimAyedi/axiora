import 'model_utils.dart';
// status mte3 constat: draft wala submitted
enum ConstatStatus {
  draft,
  submitted;
  // n7awlou enum l string bech yetkhazen fi Firestore
  String get value => name;
  // n7awlou string jeya mel Firestore l enum
  static ConstatStatus fromValue(String? value) {
    return ConstatStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ConstatStatus.draft,
    );
  }
}

class Constat {
  const Constat({
    required this.id,
    required this.userId,
    required this.referenceNumber,
    required this.status,
    required this.photoScanIds,
    required this.supportingDocumentScanIds,
    required this.isAutoFilled,
    required this.createdAt,
    required this.updatedAt,
    this.accidentDateTime,
    this.accidentLocation,
    this.accidentDescription,
    this.notes,
    this.extractedEntities,
    this.driverProfileId,
    this.vehicleProfileId,
    this.insuranceProfileId,
    this.driverSnapshot,
    this.vehicleSnapshot,
    this.insuranceSnapshot,
    this.submittedAt,
    this.approvalStatus = 'none',
    this.approvalRequestedToUid,
    this.approvalRequestedToInsuranceNumber,
    this.approvalRequestedAt,
    this.approvalRespondedAt,
    this.approvalResponse,
    this.partyBDriverSnapshot,
    this.partyBVehicleSnapshot,
    this.partyBInsuranceSnapshot,
    this.partyBCompletedAt,
    this.partyBCompletedByUid,
    this.partyAInsuranceSnapshot,
    this.partyBTargetInsuranceSnapshot,
    this.photoScansSnapshot,
    this.adminReviewStatus,
    this.adminReviewedAt,
    this.adminReviewedByUid,
  });

  final String id;
  final String userId;
  final String referenceNumber;
  final ConstatStatus status;
  final DateTime? accidentDateTime;
  final String? accidentLocation;
  final String? accidentDescription;
  final String? notes;
  final List<Map<String, dynamic>>? extractedEntities;
  final String? driverProfileId;
  final String? vehicleProfileId;
  final String? insuranceProfileId;
  final Map<String, dynamic>? driverSnapshot;
  final Map<String, dynamic>? vehicleSnapshot;
  final Map<String, dynamic>? insuranceSnapshot;
  final List<String> photoScanIds;
  final List<String> supportingDocumentScanIds;
    // true ken data t3abbet automatiquement mel OCR
  final bool isAutoFilled;
    // dates mte3 lifecycle
  final DateTime? submittedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Approval workflow fields
    // approval workflow: none, pending, accepted, rejected
  final String approvalStatus; // 'none', 'pending', 'accepted', 'rejected'
  final String? approvalRequestedToUid;
  final String? approvalRequestedToInsuranceNumber;
  final DateTime? approvalRequestedAt;
  final DateTime? approvalRespondedAt;
  final String? approvalResponse; // 'accepted' or 'rejected'

  // Party B (second party) information fields
  final Map<String, dynamic>? partyBDriverSnapshot;
  final Map<String, dynamic>? partyBVehicleSnapshot;
  final Map<String, dynamic>? partyBInsuranceSnapshot;
  final DateTime? partyBCompletedAt;
  final String? partyBCompletedByUid;

  // Party A own insurance and Party B target insurance (entered by Party A)
  final Map<String, dynamic>? partyAInsuranceSnapshot;
  final Map<String, dynamic>? partyBTargetInsuranceSnapshot;

  // Compact snapshot of photo scans embedded at approval-request time so
  // Party B can view damage photos and cost estimation without needing direct
  // access to the owner's scans subcollection.
  final List<Map<String, dynamic>>? photoScansSnapshot;

  // Admin final-approval fields
  final String? adminReviewStatus;   // null | 'approved'
  final DateTime? adminReviewedAt;
  final String? adminReviewedByUid;

  Constat copyWith({
    String? id,
    String? userId,
    String? referenceNumber,
    ConstatStatus? status,
    Object? accidentDateTime = unset,
    Object? accidentLocation = unset,
    Object? accidentDescription = unset,
    Object? notes = unset,
    Object? extractedEntities = unset,
    Object? driverProfileId = unset,
    Object? vehicleProfileId = unset,
    Object? insuranceProfileId = unset,
    Object? driverSnapshot = unset,
    Object? vehicleSnapshot = unset,
    Object? insuranceSnapshot = unset,
    List<String>? photoScanIds,
    List<String>? supportingDocumentScanIds,
    bool? isAutoFilled,
    Object? submittedAt = unset,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? approvalStatus,
    Object? approvalRequestedToUid = unset,
    Object? approvalRequestedToInsuranceNumber = unset,
    Object? approvalRequestedAt = unset,
    Object? approvalRespondedAt = unset,
    Object? approvalResponse = unset,
    Object? partyBDriverSnapshot = unset,
    Object? partyBVehicleSnapshot = unset,
    Object? partyBInsuranceSnapshot = unset,
    Object? partyBCompletedAt = unset,
    Object? partyBCompletedByUid = unset,
    Object? partyAInsuranceSnapshot = unset,
    Object? partyBTargetInsuranceSnapshot = unset,
    Object? photoScansSnapshot = unset,
    Object? adminReviewStatus = unset,
    Object? adminReviewedAt = unset,
    Object? adminReviewedByUid = unset,
  }) {
    return Constat(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      status: status ?? this.status,
      accidentDateTime: identical(accidentDateTime, unset)
          ? this.accidentDateTime
          : accidentDateTime as DateTime?,
      accidentLocation: identical(accidentLocation, unset)
          ? this.accidentLocation
          : accidentLocation as String?,
      accidentDescription: identical(accidentDescription, unset)
          ? this.accidentDescription
          : accidentDescription as String?,
      notes: identical(notes, unset) ? this.notes : notes as String?,
      extractedEntities: identical(extractedEntities, unset)
          ? this.extractedEntities
          : (extractedEntities as List<Map<String, dynamic>>?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList(),
      driverProfileId: identical(driverProfileId, unset)
          ? this.driverProfileId
          : driverProfileId as String?,
      vehicleProfileId: identical(vehicleProfileId, unset)
          ? this.vehicleProfileId
          : vehicleProfileId as String?,
      insuranceProfileId: identical(insuranceProfileId, unset)
          ? this.insuranceProfileId
          : insuranceProfileId as String?,
      driverSnapshot: identical(driverSnapshot, unset)
          ? this.driverSnapshot
          : mapCopy(driverSnapshot as Map<String, dynamic>?),
      vehicleSnapshot: identical(vehicleSnapshot, unset)
          ? this.vehicleSnapshot
          : mapCopy(vehicleSnapshot as Map<String, dynamic>?),
      insuranceSnapshot: identical(insuranceSnapshot, unset)
          ? this.insuranceSnapshot
          : mapCopy(insuranceSnapshot as Map<String, dynamic>?),
      photoScanIds: photoScanIds == null
          ? this.photoScanIds
          : stringListCopy(photoScanIds),
      supportingDocumentScanIds: supportingDocumentScanIds == null
          ? this.supportingDocumentScanIds
          : stringListCopy(supportingDocumentScanIds),
      isAutoFilled: isAutoFilled ?? this.isAutoFilled,
      submittedAt: identical(submittedAt, unset)
          ? this.submittedAt
          : submittedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvalRequestedToUid: identical(approvalRequestedToUid, unset)
          ? this.approvalRequestedToUid
          : approvalRequestedToUid as String?,
      approvalRequestedToInsuranceNumber:
          identical(approvalRequestedToInsuranceNumber, unset)
          ? this.approvalRequestedToInsuranceNumber
          : approvalRequestedToInsuranceNumber as String?,
      approvalRequestedAt: identical(approvalRequestedAt, unset)
          ? this.approvalRequestedAt
          : approvalRequestedAt as DateTime?,
      approvalRespondedAt: identical(approvalRespondedAt, unset)
          ? this.approvalRespondedAt
          : approvalRespondedAt as DateTime?,
      approvalResponse: identical(approvalResponse, unset)
          ? this.approvalResponse
          : approvalResponse as String?,
      partyBDriverSnapshot: identical(partyBDriverSnapshot, unset)
          ? this.partyBDriverSnapshot
          : mapCopy(partyBDriverSnapshot as Map<String, dynamic>?),
      partyBVehicleSnapshot: identical(partyBVehicleSnapshot, unset)
          ? this.partyBVehicleSnapshot
          : mapCopy(partyBVehicleSnapshot as Map<String, dynamic>?),
      partyBInsuranceSnapshot: identical(partyBInsuranceSnapshot, unset)
          ? this.partyBInsuranceSnapshot
          : mapCopy(partyBInsuranceSnapshot as Map<String, dynamic>?),
      partyBCompletedAt: identical(partyBCompletedAt, unset)
          ? this.partyBCompletedAt
          : partyBCompletedAt as DateTime?,
      partyBCompletedByUid: identical(partyBCompletedByUid, unset)
          ? this.partyBCompletedByUid
          : partyBCompletedByUid as String?,
      partyAInsuranceSnapshot: identical(partyAInsuranceSnapshot, unset)
          ? this.partyAInsuranceSnapshot
          : mapCopy(partyAInsuranceSnapshot as Map<String, dynamic>?),
      partyBTargetInsuranceSnapshot:
          identical(partyBTargetInsuranceSnapshot, unset)
          ? this.partyBTargetInsuranceSnapshot
          : mapCopy(partyBTargetInsuranceSnapshot as Map<String, dynamic>?),
      photoScansSnapshot: identical(photoScansSnapshot, unset)
          ? this.photoScansSnapshot
          : (photoScansSnapshot as List<Map<String, dynamic>>?)
                ?.map((e) => Map<String, dynamic>.from(e))
                .toList(),
      adminReviewStatus: identical(adminReviewStatus, unset)
          ? this.adminReviewStatus
          : adminReviewStatus as String?,
      adminReviewedAt: identical(adminReviewedAt, unset)
          ? this.adminReviewedAt
          : adminReviewedAt as DateTime?,
      adminReviewedByUid: identical(adminReviewedByUid, unset)
          ? this.adminReviewedByUid
          : adminReviewedByUid as String?,
    );
  }

  factory Constat.fromJson(Map<String, dynamic> json) {
    return Constat(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      referenceNumber: json['referenceNumber'] as String? ?? '',
      status: ConstatStatus.fromValue(json['status'] as String?),
      accidentDateTime: dateTimeFromJson(json['accidentDateTime']),
      accidentLocation: json['accidentLocation'] as String?,
      accidentDescription: json['accidentDescription'] as String?,
      notes: json['notes'] as String?,
      extractedEntities: (json['extractedEntities'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      driverProfileId: json['driverProfileId'] as String?,
      vehicleProfileId: json['vehicleProfileId'] as String?,
      insuranceProfileId: json['insuranceProfileId'] as String?,
      driverSnapshot: mapCopy(mapFromJson(json['driverSnapshot'])),
      vehicleSnapshot: mapCopy(mapFromJson(json['vehicleSnapshot'])),
      insuranceSnapshot: mapCopy(mapFromJson(json['insuranceSnapshot'])),
      photoScanIds: stringListCopy(stringListFromJson(json['photoScanIds'])),
      supportingDocumentScanIds: stringListFromJson(
        json['supportingDocumentScanIds'],
      ),
      isAutoFilled: json['isAutoFilled'] as bool? ?? false,
      submittedAt: dateTimeFromJson(json['submittedAt']),
      createdAt: dateTimeFromJson(json['createdAt']) ?? DateTime.now(),
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? DateTime.now(),
      approvalStatus: json['approvalStatus'] as String? ?? 'none',
      approvalRequestedToUid: json['approvalRequestedToUid'] as String?,
      approvalRequestedToInsuranceNumber:
          json['approvalRequestedToInsuranceNumber'] as String?,
      approvalRequestedAt: dateTimeFromJson(json['approvalRequestedAt']),
      approvalRespondedAt: dateTimeFromJson(json['approvalRespondedAt']),
      approvalResponse: json['approvalResponse'] as String?,
      partyBDriverSnapshot: mapCopy(mapFromJson(json['partyBDriverSnapshot'])),
      partyBVehicleSnapshot: mapCopy(
        mapFromJson(json['partyBVehicleSnapshot']),
      ),
      partyBInsuranceSnapshot: mapCopy(
        mapFromJson(json['partyBInsuranceSnapshot']),
      ),
      partyBCompletedAt: dateTimeFromJson(json['partyBCompletedAt']),
      partyBCompletedByUid: json['partyBCompletedByUid'] as String?,
      partyAInsuranceSnapshot: mapCopy(
        mapFromJson(json['partyAInsuranceSnapshot']),
      ),
      partyBTargetInsuranceSnapshot: mapCopy(
        mapFromJson(json['partyBTargetInsuranceSnapshot']),
      ),
      photoScansSnapshot: (json['photoScansSnapshot'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      adminReviewStatus: json['adminReviewStatus'] as String?,
      adminReviewedAt: dateTimeFromJson(json['adminReviewedAt']),
      adminReviewedByUid: json['adminReviewedByUid'] as String?,
    );
  }
  // toJson t7awel Constat l Map bech yetkhazen fi Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'referenceNumber': referenceNumber,
      'status': status.value,
      'accidentDateTime': accidentDateTime?.toIso8601String(),
      'accidentLocation': accidentLocation,
      'accidentDescription': accidentDescription,
      'notes': notes,
      'extractedEntities': extractedEntities,
      'driverProfileId': driverProfileId,
      'vehicleProfileId': vehicleProfileId,
      'insuranceProfileId': insuranceProfileId,
      'driverSnapshot': driverSnapshot,
      'vehicleSnapshot': vehicleSnapshot,
      'insuranceSnapshot': insuranceSnapshot,
      'photoScanIds': photoScanIds,
      'supportingDocumentScanIds': supportingDocumentScanIds,
      'isAutoFilled': isAutoFilled,
      'submittedAt': submittedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'approvalStatus': approvalStatus,
      'approvalRequestedToUid': approvalRequestedToUid,
      'approvalRequestedToInsuranceNumber': approvalRequestedToInsuranceNumber,
      'approvalRequestedAt': approvalRequestedAt?.toIso8601String(),
      'approvalRespondedAt': approvalRespondedAt?.toIso8601String(),
      'approvalResponse': approvalResponse,
      'partyBDriverSnapshot': partyBDriverSnapshot,
      'partyBVehicleSnapshot': partyBVehicleSnapshot,
      'partyBInsuranceSnapshot': partyBInsuranceSnapshot,
      'partyBCompletedAt': partyBCompletedAt?.toIso8601String(),
      'partyBCompletedByUid': partyBCompletedByUid,
      'partyAInsuranceSnapshot': partyAInsuranceSnapshot,
      'partyBTargetInsuranceSnapshot': partyBTargetInsuranceSnapshot,
      'photoScansSnapshot': photoScansSnapshot,
      'adminReviewStatus': adminReviewStatus,
      'adminReviewedAt': adminReviewedAt?.toIso8601String(),
      'adminReviewedByUid': adminReviewedByUid,
    };
  }
}
