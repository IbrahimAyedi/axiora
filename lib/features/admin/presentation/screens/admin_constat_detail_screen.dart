import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/models/document_scan.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../constat/presentation/widgets/cost_estimation_summary.dart';

// screen mte3 admin detail
// ywarri constat accepted men collection approved_constats
class AdminConstatDetailScreen extends StatefulWidget {
  const AdminConstatDetailScreen({required this.constatId, super.key});

  // id mte3 constat eli admin bech ychouf detail mte3ou
  final String constatId;

  @override
  State<AdminConstatDetailScreen> createState() =>
      _AdminConstatDetailScreenState();
}

class _AdminConstatDetailScreenState extends State<AdminConstatDetailScreen> {
  // data mte3 constat jeya mel Firestore
  Map<String, dynamic>? _data;

  // photo scans: built from photoScansSnapshot or loaded from owner's scans
  List<DocumentScan> _photoScans = const [];

  // loading state
  bool _loading = true;

  // error message ken fama problem
  String? _error;

  // true fi wakt admin approve action
  bool _approving = false;

  @override
  void initState() {
    super.initState();

    // ki screen tet7al, nloadiw constat detail
    _load();
  }

  // tloadi constat mel approved_constats
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _photoScans = const [];
    });

    try {
      // njibou constat men top-level collection approved_constats
      final doc = await FirebaseFirestore.instance
          .collection('approved_constats')
          .doc(widget.constatId)
          .get();

      // ken constat mawjoudch, nwarriw error
      if (!doc.exists) {
        if (mounted) {
          setState(() {
            _error = 'Constat not found in approved_constats.';
            _loading = false;
          });
        }
        return;
      }

      // ken doc mawjoud, n7otou data fi state
      if (mounted) {
        setState(() {
          _data = <String, dynamic>{...doc.data()!, 'id': doc.id};
          _loading = false;
        });
        // Populate _photoScans from snapshot or owner scans subcollection
        _loadPhotoScansIfNeeded();
      }
    } catch (e) {
      // ken fama erreur fi Firestore
      if (mounted) {
        setState(() {
          _error = 'Failed to load constat: $e';
          _loading = false;
        });
      }
    }
  }

  // Primary: reconstruct scans from embedded photoScansSnapshot.
  // Fallback: if snapshot is null/empty and ownerUid + photoScanIds are present,
  // read each scan doc from users/{ownerUid}/scans/{scanId} so admin can still
  // see damage thumbnails and cost estimate for older constats.
  Future<void> _loadPhotoScansIfNeeded() async {
    final data = _data;
    if (data == null) return;

    // Primary path — snapshot embedded in approved_constats document
    final fromSnapshot = _DetailBody._buildScans(data['photoScansSnapshot']);
    if (fromSnapshot.isNotEmpty) {
      if (mounted) setState(() => _photoScans = fromSnapshot);
      return;
    }

    // Fallback path — read individual scan docs from owner's scans subcollection
    final ownerUid = data['ownerUid'] as String?;
    final rawIds = data['photoScanIds'];
    final scanIds = rawIds is List
        ? rawIds
              .whereType<Object>()
              .map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList()
        : <String>[];

    if (ownerUid == null || ownerUid.isEmpty || scanIds.isEmpty) return;

    debugPrint(
      '[AdminPhotos] photoScansSnapshot missing — fetching '
      '${scanIds.length} scan(s) from users/$ownerUid/scans/',
    );

    try {
      final scans = <DocumentScan>[];
      for (final scanId in scanIds) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(ownerUid)
              .collection('scans')
              .doc(scanId)
              .get();
          if (doc.exists) {
            scans.add(
              DocumentScan.fromJson(<String, dynamic>{
                'id': doc.id,
                ...doc.data()!,
              }),
            );
          }
        } catch (e) {
          debugPrint('[AdminPhotos] Could not load scan $scanId: $e');
        }
      }
      debugPrint(
        '[AdminPhotos] Loaded ${scans.length} scan(s) from owner subcollection',
      );
      if (mounted) setState(() => _photoScans = scans);
    } catch (e) {
      debugPrint('[AdminPhotos] Error loading scans: $e');
    }
  }

  // admin yapprovi constat: yupdati approved_constats + owner constat + notifications
  Future<void> _approveConstat() async {
    final data = _data;
    if (data == null) return;

    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final constatId = widget.constatId;
    final ownerUid = data['ownerUid'] as String? ?? '';
    final approverUid = data['approverUid'] as String?;

    if (ownerUid.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot approve: owner UID missing.')),
        );
      }
      return;
    }

    setState(() => _approving = true);

    try {
      final now = DateTime.now().toIso8601String();
      final adminFields = <String, dynamic>{
        'adminReviewStatus': 'approved',
        'adminReviewedAt': now,
        'adminReviewedByUid': adminUid,
      };

      // 1. Update approved_constats (admin has full write access)
      await FirebaseFirestore.instance
          .collection('approved_constats')
          .doc(constatId)
          .update(adminFields);

      debugPrint('[AdminApproval] approved_constats/$constatId updated');

      // 2. Try to update owner constat — requires Firestore rule allowing
      //    authenticated users to update accepted constats with admin fields.
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerUid)
            .collection('constats')
            .doc(constatId)
            .update(adminFields);
        debugPrint('[AdminApproval] users/$ownerUid/constats/$constatId updated');
      } on FirebaseException catch (e) {
        debugPrint('[AdminApproval] Could not update owner constat: ${e.code} ${e.message}');
      }

      // 3. Notify User A (owner)
      await _sendAdminApprovalNotification(
        constatId: constatId,
        targetUid: ownerUid,
        ownerUid: ownerUid,
        isOwner: true,
      );

      // 4. Notify User B (approver) if UID is known
      if (approverUid != null && approverUid.isNotEmpty) {
        await _sendAdminApprovalNotification(
          constatId: constatId,
          targetUid: approverUid,
          ownerUid: ownerUid,
          isOwner: false,
        );
      }

      // 5. Refresh local data so badge appears immediately
      if (mounted) {
        setState(() {
          _data = <String, dynamic>{..._data!, ...adminFields};
          _approving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Constat approved. Notifications sent.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      debugPrint('[AdminApproval] ERROR: $e');
      if (mounted) {
        setState(() => _approving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e')),
        );
      }
    }
  }

  // tcreati notification mte3 admin approval lel user el muhedd
  Future<void> _sendAdminApprovalNotification({
    required String constatId,
    required String targetUid,
    required String ownerUid,
    required bool isOwner,
  }) async {
    final notificationId = 'notif_admin_approved_$constatId';
    final body = isOwner
        ? 'Your constat has been approved by admin.'
        : 'The constat has been approved by admin.';

    debugPrint(
      '[NotifAdminApproval] Writing users/$targetUid/notifications/$notificationId',
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid)
          .collection('notifications')
          .doc(notificationId)
          .set({
            'id': notificationId,
            'userId': targetUid,
            'type': 'admin_approval',
            'title': 'Constat approved',
            'body': body,
            'constatId': constatId,
            'ownerUid': ownerUid,
            'read': false,
            'createdAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
      debugPrint(
        '[NotifAdminApproval] SUCCESS — $notificationId for $targetUid',
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint(
          '[NotifAdminApproval] PERMISSION_DENIED — $notificationId for $targetUid. '
          'Check Firestore rules: allow create, update must be set for '
          'users/{userId}/notifications/{notifId}.',
        );
      } else {
        debugPrint(
          '[NotifAdminApproval] ERROR — ${e.code}: ${e.message}',
        );
      }
    } catch (e) {
      debugPrint('[NotifAdminApproval] ERROR — $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // appbar mte3 admin detail
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // reference number wala default title
            Text(_data?['referenceNumber'] as String? ?? 'Constat detail'),

            // subtitle yوضح eli admin view read only
            Text('Admin view — read only', style: theme.textTheme.bodySmall),
          ],
        ),
      ),

      // body mte3 screen
      body: SafeArea(
        child: _loading
            // loading indicator
            ? const Center(child: CircularProgressIndicator())

            // error view ken fama erreur
            : _error != null
            ? _ErrorView(
                message: _error!,
                onBack: () => context.go(RouteNames.adminDashboardPath),
              )

            // detail body ken data loaded
            : _DetailBody(
                data: _data!,
                photoScans: _photoScans,
                onApprove: _approveConstat,
                isApproving: _approving,
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main detail body
// ---------------------------------------------------------------------------

// widget ywarri details mte3 constat accepted
class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.data,
    required this.photoScans,
    required this.onApprove,
    required this.isApproving,
  });

  // data mte3 constat
  final Map<String, dynamic> data;

  // photo scans — already resolved by the state (snapshot or owner subcollection)
  final List<DocumentScan> photoScans;

  // callback ki admin yapprovi
  final VoidCallback onApprove;

  // true waqt approve action
  final bool isApproving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // basic metadata
    final referenceNumber = data['referenceNumber'] as String? ?? '--';
    final approvalStatus = data['approvalStatus'] as String? ?? 'accepted';
    final createdAt = _fmt(data['createdAt'] as String?);
    final submittedAt = _fmt(data['submittedAt'] as String?);
    final acceptedAt = _fmt(data['approvalRespondedAt'] as String?);
    final mirroredAt = _fmt(data['mirroredAt'] as String?);

    // snapshots mte3 Party A
    final driverSnapshot = _asMap(data['driverSnapshot']);
    final vehicleSnapshot = _asMap(data['vehicleSnapshot']);

    // Party A insurance: prefer partyAInsuranceSnapshot, fallback insuranceSnapshot
    final insuranceSnapshot =
        _asMap(data['partyAInsuranceSnapshot']) ??
        _asMap(data['insuranceSnapshot']);

    // assurance target mte3 Party B
    final partyBTargetInsuranceSnapshot = _asMap(
      data['partyBTargetInsuranceSnapshot'],
    );

    // snapshots mte3 Party B
    final partyBDriverSnapshot = _asMap(data['partyBDriverSnapshot']);
    final partyBVehicleSnapshot = _asMap(data['partyBVehicleSnapshot']);
    final partyBInsuranceSnapshot = _asMap(data['partyBInsuranceSnapshot']);

    // notes w photos
    final notes = data['notes'] as String?;
    final photoScanIds = _strList(data['photoScanIds']);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // header fih reference, status w dates
          _StatusHeader(
            referenceNumber: referenceNumber,
            approvalStatus: approvalStatus,
            createdAt: createdAt,
            submittedAt: submittedAt,
            acceptedAt: acceptedAt,
            mirroredAt: mirroredAt,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 16),

          // section mte3 accident info
          SectionCard(
            title: 'Accident information',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row('Date & time', _fmt(data['accidentDateTime'] as String?)),
                _Row('Location', data['accidentLocation'] as String? ?? '--'),
                _Row(
                  'Description',
                  data['accidentDescription'] as String? ?? '--',
                ),
                if (notes != null && notes.isNotEmpty)
                  _Row('Notes / damage', notes),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // divider mte3 Party A
          _PartyDivider(
            label: 'Party A',
            subtitle: 'Constat owner / initiator',
            color: const Color(0xFF1565C0),
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 12),

          // Party A driver info
          SectionCard(
            title: 'Driver',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row('Full name', _snap(driverSnapshot, 'fullName')),
                _Row('License number', _snap(driverSnapshot, 'licenseNumber')),
                _Row('CIN / National ID', _snap(driverSnapshot, 'nationalId')),
                _Row('Phone', _snap(driverSnapshot, 'phoneNumber')),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Party A vehicle info
          SectionCard(
            title: 'Vehicle',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row('Plate number', _snap(vehicleSnapshot, 'plateNumber')),
                _Row('Brand', _snap(vehicleSnapshot, 'brand')),
                _Row('Model', _snap(vehicleSnapshot, 'model')),
                _Row('VIN', _snap(vehicleSnapshot, 'vin')),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Party A insurance info
          SectionCard(
            title: 'Insurance',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row(
                  'Insurance number',
                  _snap(insuranceSnapshot, 'insuranceNumber'),
                ),
                _Row('Company', _snap(insuranceSnapshot, 'companyName')),
                _Row(
                  'Policy holder',
                  _snap(insuranceSnapshot, 'policyHolderName'),
                ),
                _Row('Policy type', _snap(insuranceSnapshot, 'policyType')),
              ],
            ),
          ),

          // target insurance number eli tbaathlou approval request
          if (partyBTargetInsuranceSnapshot != null) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: 'Other party target insurance',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Row(
                    'Insurance number',
                    _snap(partyBTargetInsuranceSnapshot, 'insuranceNumber'),
                  ),
                  _Row(
                    'Company',
                    _snap(partyBTargetInsuranceSnapshot, 'companyName'),
                  ),
                  _Row(
                    'Policy holder',
                    _snap(partyBTargetInsuranceSnapshot, 'policyHolderName'),
                  ),
                  _Row(
                    'Policy type',
                    _snap(partyBTargetInsuranceSnapshot, 'policyType'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // divider mte3 Party B
          _PartyDivider(
            label: 'Party B',
            subtitle: 'Second party — completed info',
            color: const Color(0xFF2E7D32),
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 12),

          // Party B driver info
          SectionCard(
            title: 'Driver',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row('Full name', _snap(partyBDriverSnapshot, 'fullName')),
                _Row(
                  'License number',
                  _snap(partyBDriverSnapshot, 'licenseNumber'),
                ),
                _Row(
                  'CIN / National ID',
                  _snap(partyBDriverSnapshot, 'nationalId'),
                ),
                _Row('Phone', _snap(partyBDriverSnapshot, 'phoneNumber')),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Party B vehicle info
          SectionCard(
            title: 'Vehicle',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row(
                  'Plate number',
                  _snap(partyBVehicleSnapshot, 'plateNumber'),
                ),
                _Row('Brand', _snap(partyBVehicleSnapshot, 'brand')),
                _Row('Model', _snap(partyBVehicleSnapshot, 'model')),
                _Row('VIN', _snap(partyBVehicleSnapshot, 'vin')),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Party B insurance info
          SectionCard(
            title: 'Insurance',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row(
                  'Insurance number',
                  _snap(partyBInsuranceSnapshot, 'insuranceNumber'),
                ),
                _Row('Company', _snap(partyBInsuranceSnapshot, 'companyName')),
                _Row(
                  'Policy holder',
                  _snap(partyBInsuranceSnapshot, 'policyHolderName'),
                ),
                _Row(
                  'Policy type',
                  _snap(partyBInsuranceSnapshot, 'policyType'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // section mte3 approval metadata
          SectionCard(
            title: 'Approval details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row('Status', approvalStatus),
                _Row(
                  'Requested to insurance',
                  data['approvalRequestedToInsuranceNumber'] as String? ?? '--',
                ),
                _Row(
                  'Requested at',
                  _fmt(data['approvalRequestedAt'] as String?),
                ),
                _Row('Accepted at', acceptedAt),
                _Row('Owner UID', data['ownerUid'] as String? ?? '--'),
                _Row('Approver UID', data['approverUid'] as String? ?? '--'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // section mte3 damage photos + cost estimate (uses embedded snapshot)
          _PhotoEvidenceSection(
            photoScans: photoScans,
            photoScanIds: photoScanIds,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: 20),

          // ── Admin final approval section ─────────────────────────────────
          _AdminActionSection(
            adminReviewStatus: data['adminReviewStatus'] as String?,
            adminReviewedAt: _fmt(data['adminReviewedAt'] as String?),
            adminReviewedByUid: data['adminReviewedByUid'] as String?,
            onApprove: onApprove,
            isApproving: isApproving,
            isDark: isDark,
            theme: theme,
          ),
        ],
      ),
    );
  }

  // t7awel dynamic value l Map<String, dynamic>
  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return null;
  }

  // t7awel dynamic value l List<String>
  static List<String> _strList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }

  // reconstruct DocumentScan objects from photoScansSnapshot list
  static List<DocumentScan> _buildScans(dynamic raw) {
    if (raw is! List || raw.isEmpty) return const [];
    return raw
        .whereType<Map>()
        .map((m) {
          try {
            return DocumentScan.fromJson(
              m.map((k, v) => MapEntry(k.toString(), v)),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<DocumentScan>()
        .toList();
  }

  // tjib value men snapshot wala '--'
  static String _snap(Map<String, dynamic>? snap, String key) {
    final v = snap?[key];
    if (v == null) return '--';
    final s = v.toString().trim();
    return s.isEmpty ? '--' : s;
  }

  // tformat date string l yyyy-MM-dd HH:mm
  static String _fmt(String? raw) {
    if (raw == null || raw.isEmpty) return '--';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }
}

// ---------------------------------------------------------------------------
// Status header banner
// ---------------------------------------------------------------------------

// widget ywarri header mte3 status w dates
class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.referenceNumber,
    required this.approvalStatus,
    required this.createdAt,
    required this.submittedAt,
    required this.acceptedAt,
    required this.mirroredAt,
    required this.isDark,
    required this.theme,
  });

  final String referenceNumber;
  final String approvalStatus;
  final String createdAt;
  final String submittedAt;
  final String acceptedAt;
  final String mirroredAt;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),

      // decoration mte3 status banner
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1B2A1E), const Color(0xFF1A3322)]
              : [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.green.shade800.withValues(alpha: 0.4)
              : Colors.green.shade200,
        ),
      ),

      // content mte3 banner
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // icon accepted/verified
              Icon(
                Icons.verified_outlined,
                size: 28,
                color: isDark ? Colors.green.shade300 : Colors.green.shade700,
              ),
              const SizedBox(width: 10),

              // reference number
              Expanded(
                child: Text(
                  referenceNumber,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: isDark ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: isDark ? 0.4 : 0.3),
                  ),
                ),
                child: Text(
                  approvalStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.green.shade300
                        : Colors.green.shade800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // timeline mte3 creation/submission/acceptance
          _TimeLine(label: 'Created', value: createdAt, theme: theme),
          if (submittedAt != '--')
            _TimeLine(label: 'Submitted', value: submittedAt, theme: theme),
          _TimeLine(
            label: 'Accepted',
            value: acceptedAt,
            theme: theme,
            highlight: true,
            isDark: isDark,
          ),
          _TimeLine(
            label: 'Mirrored to admin',
            value: mirroredAt,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

// row sghira lel timeline dates
class _TimeLine extends StatelessWidget {
  const _TimeLine({
    required this.label,
    required this.value,
    required this.theme,
    this.highlight = false,
    this.isDark = false,
  });

  final String label;
  final String value;
  final ThemeData theme;
  final bool highlight;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // color yetbadel ken timeline highlighted
    final textColor = highlight
        ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
        : theme.colorScheme.onSurface.withValues(alpha: 0.75);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // label mte3 date
          Text(
            '$label:  ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),

          // value mte3 date
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Party divider
// ---------------------------------------------------------------------------

// divider yfar9 bin Party A w Party B
class _PartyDivider extends StatelessWidget {
  const _PartyDivider({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.theme,
  });

  final String label;
  final String subtitle;
  final Color color;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // badge mte3 party
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.35 : 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // subtitle w divider line
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              Divider(
                height: 12,
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Photo evidence section — shows thumbnails + cost estimate when snapshot
// is available, falls back to scan-ID list for older constats.
// ---------------------------------------------------------------------------

class _PhotoEvidenceSection extends StatelessWidget {
  const _PhotoEvidenceSection({
    required this.photoScans,
    required this.photoScanIds,
    required this.isDark,
    required this.theme,
  });

  final List<DocumentScan> photoScans;
  final List<String> photoScanIds;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    // ── Case 1: snapshot available — show visuals ──────────────────────────
    if (photoScans.isNotEmpty) {
      final hasCost = CostEstimationSummary.hasData(photoScans);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'Damage photos',
            icon: Icons.camera_alt_outlined,
            iconColor: Colors.orange,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${photoScans.length} photo(s) attached',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: photoScans
                      .map((s) => _AdminPhotoThumbnail(scan: s))
                      .toList(),
                ),
              ],
            ),
          ),
          if (hasCost) ...[
            const SizedBox(height: 12),
            SectionCard(
              title: 'Damage cost estimate',
              icon: Icons.monetization_on_outlined,
              iconColor: const Color(0xFF2E7D32),
              child: CostEstimationSummary(photoScans: photoScans),
            ),
          ],
        ],
      );
    }

    // ── Case 2: no snapshot — fallback ─────────────────────────────────────
    return SectionCard(
      title: 'Damage photos',
      icon: Icons.camera_alt_outlined,
      iconColor: Colors.orange,
      child: photoScanIds.isEmpty
          ? Text(
              'No damage photos were linked to this constat.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Photo preview unavailable for this older constat.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...photoScanIds.map(
                  (id) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.photo_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.45,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            id,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Admin photo thumbnail — network-only (no local file path in admin context)
// ---------------------------------------------------------------------------

class _AdminPhotoThumbnail extends StatelessWidget {
  const _AdminPhotoThumbnail({required this.scan});

  final DocumentScan scan;

  @override
  Widget build(BuildContext context) {
    final url = scan.thumbnailUrl?.isNotEmpty == true
        ? scan.thumbnailUrl!
        : scan.fileUrl;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
              )
            : const _PhotoPlaceholder(),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.broken_image_outlined,
        color: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.3),
        size: 32,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Admin final approval action section
// ---------------------------------------------------------------------------

class _AdminActionSection extends StatelessWidget {
  const _AdminActionSection({
    required this.adminReviewStatus,
    required this.adminReviewedAt,
    required this.adminReviewedByUid,
    required this.onApprove,
    required this.isApproving,
    required this.isDark,
    required this.theme,
  });

  final String? adminReviewStatus;
  final String adminReviewedAt;
  final String? adminReviewedByUid;
  final VoidCallback onApprove;
  final bool isApproving;
  final bool isDark;
  final ThemeData theme;

  bool get _isApproved => adminReviewStatus == 'approved';

  @override
  Widget build(BuildContext context) {
    if (_isApproved) {
      // green badge — final approval already done
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.green.shade900.withValues(alpha: 0.35)
              : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.green.shade700.withValues(alpha: 0.5)
                : Colors.green.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.verified_rounded,
              color: isDark ? Colors.green.shade300 : Colors.green.shade700,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Final approval completed',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.green.shade300
                          : Colors.green.shade800,
                    ),
                  ),
                  if (adminReviewedAt != '--') ...[
                    const SizedBox(height: 3),
                    Text(
                      'Approved at: $adminReviewedAt',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? Colors.green.shade400
                            : Colors.green.shade700,
                      ),
                    ),
                  ],
                  if (adminReviewedByUid != null &&
                      adminReviewedByUid!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'By: $adminReviewedByUid',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // approve button — constat accepted but not yet admin-approved
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor:
              isDark ? Colors.green.shade700 : Colors.green.shade700,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: isApproving ? null : onApprove,
        icon: isApproving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.verified_outlined, color: Colors.white),
        label: Text(
          isApproving ? 'Approving…' : 'Approve final report',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared row widget
// ---------------------------------------------------------------------------

// row reusable taffichi label w value
class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // label
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 3),

          // value
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

// widget yban ken fama error fi loading
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // error icon
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 16),

            // error message
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // button yarja3 lel dashboard
            FilledButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}