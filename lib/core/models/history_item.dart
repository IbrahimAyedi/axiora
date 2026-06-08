import 'constat.dart';
import 'document_scan.dart';
import 'model_utils.dart';
// type mte3 history item: scan wala constat

enum HistoryItemType {
  scan,
  constat;
  // n7awlou enum l string bech yetkhazen

  String get value => name;

  static HistoryItemType fromValue(String? value) {
    return HistoryItemType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => HistoryItemType.scan,
    );
  }
}
// model ymathel item fi history screen

class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.referenceId,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    this.status,
  });

  final String id;
  final String userId;
  final HistoryItemType type;
  final String referenceId;
  final String title;
  final String subtitle;
  final String? status;
  final DateTime createdAt;
  // ta3mel HistoryItem men DocumentScan
  factory HistoryItem.fromDocumentScan(DocumentScan scan) {
    return HistoryItem(
      id: 'scan_${scan.id}',
      userId: scan.userId,
      type: HistoryItemType.scan,
      referenceId: scan.id,
      title: scan.scanType.value,
      subtitle: scan.notes ?? scan.ocrRawText ?? 'Scan in progress',
      status: scan.status.value,
      createdAt: scan.createdAt,
    );
  }
  // ta3mel HistoryItem men Constat

  factory HistoryItem.fromConstat(Constat constat) {
    return HistoryItem(
      id: 'constat_${constat.id}',
      userId: constat.userId,
      type: HistoryItemType.constat,
      referenceId: constat.id,
      title: constat.referenceNumber,
      subtitle:
          constat.accidentLocation ??
          constat.accidentDescription ??
          'Draft constat',
      status: constat.status.value,
      createdAt: constat.createdAt,
    );
  }

  HistoryItem copyWith({
    String? id,
    String? userId,
    HistoryItemType? type,
    String? referenceId,
    String? title,
    String? subtitle,
    Object? status = unset,
    DateTime? createdAt,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      status: identical(status, unset) ? this.status : status as String?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: HistoryItemType.fromValue(json['type'] as String?),
      referenceId: json['referenceId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      status: json['status'] as String?,
      createdAt: dateTimeFromJson(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.value,
      'referenceId': referenceId,
      'title': title,
      'subtitle': subtitle,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
