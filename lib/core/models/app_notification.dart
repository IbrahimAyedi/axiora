import 'model_utils.dart';
// model ymathel notification fi app

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.constatId,
    this.ownerUid,
  });
  // basic data mte3 notification

  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final String? constatId;

  /// UID of the user who owns the constat referenced by [constatId].
  /// Present on "constat_request" notifications so User B can navigate to
  /// users/{ownerUid}/constats/{constatId} even though User A owns the data.
  /// Null on old notifications created before this field was added.
  final String? ownerUid;

  final bool read;
  final DateTime createdAt;
  // copyWith tbadel fields mou3ayna w tkhalI be9i kif ma howa
  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    Object? constatId = unset,
    Object? ownerUid = unset,
    bool? read,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      constatId: identical(constatId, unset)
          ? this.constatId
          : constatId as String?,
      ownerUid: identical(ownerUid, unset)
          ? this.ownerUid
          : ownerUid as String?,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  // fromJson t7awel data jeya mel Firestore l AppNotification
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: json['type'] as String? ?? 'info',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      constatId: json['constatId'] as String?,
      ownerUid: json['ownerUid'] as String?,
      read: json['read'] as bool? ?? false,
      createdAt: dateTimeFromJson(json['createdAt']) ?? DateTime.now(),
    );
  }
  // toJson t7awel AppNotification l Map bech تتخزن fi Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'constatId': constatId,
      'ownerUid': ownerUid,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
