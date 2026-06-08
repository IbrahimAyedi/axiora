import 'model_utils.dart';
// type mte3 document eli user scanneh

enum DocumentScanType {
  insurance,
  carteGrise,
  driverLicense,
  vehiclePhoto,
  other;
  // n7awlou enum l string bech yetkhazen fi Firestore

  String get value => switch (this) {
    DocumentScanType.insurance => 'insurance',
    DocumentScanType.carteGrise => 'carte_grise',
    DocumentScanType.driverLicense => 'driver_license',
    DocumentScanType.vehiclePhoto => 'vehicle_photo',
    DocumentScanType.other => 'other',
  };
  // n7awlou string jeya mel Firestore l enum
  static DocumentScanType fromValue(String? value) {
    return DocumentScanType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DocumentScanType.other,
    );
  }
}
// status mte3 scan: pending, processing, completed wala failed
enum DocumentScanStatus {
  pending,
  processing,
  completed,
  failed;

  String get value => name;

  static DocumentScanStatus fromValue(String? value) {
    return DocumentScanStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DocumentScanStatus.pending,
    );
  }
}

enum ProfileType {
  insurance,
  vehicle,
  driver;

  String get value => name;
  // n7awlou string l ProfileType, w ken null nraj3ou null
  static ProfileType? fromNullableValue(String? value) {
    if (value == null || value.isEmpty) return null;

    return ProfileType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ProfileType.insurance,
    );
  }
}
// model ymathel scan document wala image fi app
class DocumentScan {
  const DocumentScan({
    required this.id,
    required this.userId,
    required this.scanType,
    required this.status,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.fileUrl,
    this.localFilePath,
    this.thumbnailUrl,
    this.ocrRawText,
    this.extractedData,
    this.confidenceScore,
    this.qualityScore,
    this.relatedProfileId,
    this.relatedProfileType,
    this.notes,
    this.errorMessage,
    this.processedAt,
  });
  // basic scan info
  final String id;
  final String userId;
  final DocumentScanType scanType;
  final DocumentScanStatus status;
  final String source;
    // file/image paths
  final String? fileUrl;
  final String? localFilePath;
  final String? thumbnailUrl;
    // OCR result w data extracted
  final String? ocrRawText;
  final Map<String, dynamic>? extractedData;
    // confidence w quality scores
  final double? confidenceScore;
  final double? qualityScore;
    // profile linked b scan, exemple driver/vehicle/insurance
  final String? relatedProfileId;
  final ProfileType? relatedProfileType;
  final String? notes;
  final String? errorMessage;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentScan copyWith({
    String? id,
    String? userId,
    DocumentScanType? scanType,
    DocumentScanStatus? status,
    String? source,
    Object? fileUrl = unset,
    Object? localFilePath = unset,
    Object? thumbnailUrl = unset,
    Object? ocrRawText = unset,
    Object? extractedData = unset,
    Object? confidenceScore = unset,
    Object? qualityScore = unset,
    Object? relatedProfileId = unset,
    Object? relatedProfileType = unset,
    Object? notes = unset,
    Object? errorMessage = unset,
    Object? processedAt = unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentScan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scanType: scanType ?? this.scanType,
      status: status ?? this.status,
      source: source ?? this.source,
      fileUrl: identical(fileUrl, unset) ? this.fileUrl : fileUrl as String?,
      localFilePath: identical(localFilePath, unset)
          ? this.localFilePath
          : localFilePath as String?,
      thumbnailUrl: identical(thumbnailUrl, unset)
          ? this.thumbnailUrl
          : thumbnailUrl as String?,
      ocrRawText: identical(ocrRawText, unset)
          ? this.ocrRawText
          : ocrRawText as String?,
      extractedData: identical(extractedData, unset)
          ? this.extractedData
          : mapCopy(extractedData as Map<String, dynamic>?),
      confidenceScore: identical(confidenceScore, unset)
          ? this.confidenceScore
          : confidenceScore as double?,
      qualityScore: identical(qualityScore, unset)
          ? this.qualityScore
          : qualityScore as double?,
      relatedProfileId: identical(relatedProfileId, unset)
          ? this.relatedProfileId
          : relatedProfileId as String?,
      relatedProfileType: identical(relatedProfileType, unset)
          ? this.relatedProfileType
          : relatedProfileType as ProfileType?,
      notes: identical(notes, unset) ? this.notes : notes as String?,
      errorMessage: identical(errorMessage, unset)
          ? this.errorMessage
          : errorMessage as String?,
      processedAt: identical(processedAt, unset)
          ? this.processedAt
          : processedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  // fromJson t7awel data jeya mel Firestore l DocumentScan
  factory DocumentScan.fromJson(Map<String, dynamic> json) {
    return DocumentScan(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      scanType: DocumentScanType.fromValue(json['scanType'] as String?),
      status: DocumentScanStatus.fromValue(json['status'] as String?),
      source: json['source'] as String? ?? 'camera',
      fileUrl: json['fileUrl'] as String?,
      localFilePath: json['localFilePath'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      ocrRawText: json['ocrRawText'] as String?,
      extractedData: mapCopy(mapFromJson(json['extractedData'])),
      confidenceScore: doubleFromJson(json['confidenceScore']),
      qualityScore: doubleFromJson(json['qualityScore']),
      relatedProfileId: json['relatedProfileId'] as String?,
      relatedProfileType: ProfileType.fromNullableValue(
        json['relatedProfileType'] as String?,
      ),
      notes: json['notes'] as String?,
      errorMessage: json['errorMessage'] as String?,
      processedAt: dateTimeFromJson(json['processedAt']),
      createdAt: dateTimeFromJson(json['createdAt']) ?? DateTime.now(),
      updatedAt: dateTimeFromJson(json['updatedAt']) ?? DateTime.now(),
    );
  }
  // toJson t7awel DocumentScan l Map bech yetkhazen fi Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'scanType': scanType.value,
      'status': status.value,
      'source': source,
      'fileUrl': fileUrl,
      'localFilePath': localFilePath,
      'thumbnailUrl': thumbnailUrl,
      'ocrRawText': ocrRawText,
      'extractedData': extractedData,
      'confidenceScore': confidenceScore,
      'qualityScore': qualityScore,
      'relatedProfileId': relatedProfileId,
      'relatedProfileType': relatedProfileType?.value,
      'notes': notes,
      'errorMessage': errorMessage,
      'processedAt': processedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
