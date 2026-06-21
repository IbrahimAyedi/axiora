import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/models/document_scan.dart';
import '../../../constat/presentation/widgets/cost_estimation_summary.dart';

const _pageBackground = Color(0xFFF4F7FB);
const _cardBorder = Color(0xFFD8E2EE);
const _navy = Color(0xFF123A63);
const _blue = Color(0xFF1E6BD6);
const _green = Color(0xFF1F8A5B);
const _amber = Color(0xFFB7791F);
const _textMuted = Color(0xFF627387);

class AdminConstatDetailScreen extends StatefulWidget {
  const AdminConstatDetailScreen({required this.constatId, super.key});

  final String constatId;

  @override
  State<AdminConstatDetailScreen> createState() =>
      _AdminConstatDetailScreenState();
}

class _AdminConstatDetailScreenState extends State<AdminConstatDetailScreen> {
  Map<String, dynamic>? _data;
  List<DocumentScan> _photoScans = const [];
  bool _loading = true;
  String? _error;
  bool _approving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _photoScans = const [];
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('approved_constats')
          .doc(widget.constatId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          setState(() {
            _error = 'Constat introuvable dans approved_constats.';
            _loading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _data = <String, dynamic>{...doc.data()!, 'id': doc.id};
          _loading = false;
        });
        _loadPhotoScansIfNeeded();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger le constat: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadPhotoScansIfNeeded() async {
    final data = _data;
    if (data == null) return;

    final fromSnapshot = _DetailBody.buildScans(data['photoScansSnapshot']);
    if (fromSnapshot.isNotEmpty) {
      if (mounted) setState(() => _photoScans = fromSnapshot);
      return;
    }

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
      '[AdminPhotos] photoScansSnapshot missing - fetching '
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

      await FirebaseFirestore.instance
          .collection('approved_constats')
          .doc(constatId)
          .update(adminFields);

      debugPrint('[AdminApproval] approved_constats/$constatId updated');

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerUid)
            .collection('constats')
            .doc(constatId)
            .update(adminFields);
        debugPrint(
          '[AdminApproval] users/$ownerUid/constats/$constatId updated',
        );
      } on FirebaseException catch (e) {
        debugPrint(
          '[AdminApproval] Could not update owner constat: ${e.code} ${e.message}',
        );
      }

      await _sendAdminApprovalNotification(
        constatId: constatId,
        targetUid: ownerUid,
        ownerUid: ownerUid,
        isOwner: true,
      );

      if (approverUid != null && approverUid.isNotEmpty) {
        await _sendAdminApprovalNotification(
          constatId: constatId,
          targetUid: approverUid,
          ownerUid: ownerUid,
          isOwner: false,
        );
      }

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Approval failed: $e')));
      }
    }
  }

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
        '[NotifAdminApproval] SUCCESS - $notificationId for $targetUid',
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint(
          '[NotifAdminApproval] PERMISSION_DENIED - $notificationId for $targetUid. '
          'Check Firestore rules: allow create, update must be set for '
          'users/{userId}/notifications/{notifId}.',
        );
      } else {
        debugPrint('[NotifAdminApproval] ERROR - ${e.code}: ${e.message}');
      }
    } catch (e) {
      debugPrint('[NotifAdminApproval] ERROR - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _navy,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _data?['referenceNumber'] as String? ?? 'Détail du constat',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Revue expert admin',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorView(
                message: _error!,
                onBack: () => context.go(RouteNames.adminDashboardPath),
              )
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

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.data,
    required this.photoScans,
    required this.onApprove,
    required this.isApproving,
  });

  final Map<String, dynamic> data;
  final List<DocumentScan> photoScans;
  final VoidCallback onApprove;
  final bool isApproving;

  @override
  Widget build(BuildContext context) {
    final referenceNumber = _read(data['referenceNumber'], fallback: '--');
    final approvalStatus = _read(data['approvalStatus'], fallback: 'accepted');
    final createdAt = _fmt(data['createdAt'] as String?);
    final submittedAt = _fmt(data['submittedAt'] as String?);
    final acceptedAt = _fmt(data['approvalRespondedAt'] as String?);
    final mirroredAt = _fmt(data['mirroredAt'] as String?);
    final notes = _read(data['notes']);
    final photoScanIds = _strList(data['photoScanIds']);

    final driverSnapshot = _asMap(data['driverSnapshot']);
    final vehicleSnapshot = _asMap(data['vehicleSnapshot']);
    final insuranceSnapshot =
        _asMap(data['partyAInsuranceSnapshot']) ??
        _asMap(data['insuranceSnapshot']);
    final partyBTargetInsuranceSnapshot = _asMap(
      data['partyBTargetInsuranceSnapshot'],
    );
    final partyBDriverSnapshot = _asMap(data['partyBDriverSnapshot']);
    final partyBVehicleSnapshot = _asMap(data['partyBVehicleSnapshot']);
    final partyBInsuranceSnapshot = _asMap(data['partyBInsuranceSnapshot']);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReviewHeader(
            referenceNumber: referenceNumber,
            approvalStatus: approvalStatus,
            acceptedAt: acceptedAt,
            adminReviewStatus: data['adminReviewStatus'] as String?,
          ),
          const SizedBox(height: 16),
          _ExpertCard(
            title: "Résumé de l'accident",
            icon: Icons.assignment_outlined,
            child: _InfoGrid(
              rows: [
                _InfoRowData(
                  'Date et heure',
                  _fmt(data['accidentDateTime'] as String?),
                ),
                _InfoRowData('Lieu', _read(data['accidentLocation'])),
                _InfoRowData(
                  'Description',
                  _read(data['accidentDescription']),
                  wide: true,
                ),
                if (notes != '--')
                  _InfoRowData('Notes dégâts', notes, wide: true),
                _InfoRowData('Créé le', createdAt),
                if (submittedAt != '--') _InfoRowData('Soumis le', submittedAt),
                _InfoRowData('Accepté le', acceptedAt),
                _InfoRowData('Copié admin', mirroredAt),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ExpertCard(
            title: 'Conducteur A',
            subtitle: 'Initiateur du constat',
            icon: Icons.person_outline,
            accent: _blue,
            child: _DriverSection(
              driver: driverSnapshot,
              insurance: insuranceSnapshot,
              targetInsurance: partyBTargetInsuranceSnapshot,
            ),
          ),
          const SizedBox(height: 14),
          _ExpertCard(
            title: 'Conducteur B',
            subtitle: 'Deuxième partie',
            icon: Icons.person_add_alt_1_outlined,
            accent: _green,
            child: _DriverSection(
              driver: partyBDriverSnapshot,
              insurance: partyBInsuranceSnapshot,
            ),
          ),
          const SizedBox(height: 14),
          _ExpertCard(
            title: 'Véhicules',
            icon: Icons.directions_car_outlined,
            child: _VehiclesSection(
              vehicleA: vehicleSnapshot,
              vehicleB: partyBVehicleSnapshot,
            ),
          ),
          const SizedBox(height: 14),
          _ExpertCard(
            title: 'Photos des dégâts',
            icon: Icons.photo_library_outlined,
            accent: _amber,
            child: _PhotosDamageSection(
              photoScans: photoScans,
              photoScanIds: photoScanIds,
            ),
          ),
          const SizedBox(height: 14),
          _ExpertCard(
            title: 'Analyse IA / Coût estimé',
            icon: Icons.analytics_outlined,
            accent: _green,
            child: _AnalysisCostSection(photoScans: photoScans),
          ),
          const SizedBox(height: 14),
          _ExpertCard(
            title: 'Décision admin',
            icon: Icons.verified_user_outlined,
            accent: _blue,
            child: _DecisionSection(
              approvalStatus: approvalStatus,
              requestedInsurance:
                  data['approvalRequestedToInsuranceNumber'] as String?,
              requestedAt: _fmt(data['approvalRequestedAt'] as String?),
              ownerUid: data['ownerUid'] as String?,
              approverUid: data['approverUid'] as String?,
              adminReviewStatus: data['adminReviewStatus'] as String?,
              adminReviewedAt: _fmt(data['adminReviewedAt'] as String?),
              adminReviewedByUid: data['adminReviewedByUid'] as String?,
              onApprove: onApprove,
              isApproving: isApproving,
            ),
          ),
        ],
      ),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  static List<String> _strList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  static List<DocumentScan> buildScans(dynamic raw) {
    if (raw is! List || raw.isEmpty) return const [];
    return raw
        .whereType<Map>()
        .map((scan) {
          try {
            return DocumentScan.fromJson(
              scan.map((key, value) => MapEntry(key.toString(), value)),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<DocumentScan>()
        .toList();
  }

  static String _read(Object? value, {String fallback = '--'}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  static String _snap(Map<String, dynamic>? snapshot, String key) {
    return _read(snapshot?[key]);
  }

  static String _fmt(String? raw) {
    if (raw == null || raw.isEmpty) return '--';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({
    required this.referenceNumber,
    required this.approvalStatus,
    required this.acceptedAt,
    required this.adminReviewStatus,
  });

  final String referenceNumber;
  final String approvalStatus;
  final String acceptedAt;
  final String? adminReviewStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdminApproved = adminReviewStatus == 'approved';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F1FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.policy_outlined, color: _blue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      referenceNumber,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: _navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dossier accepté par les parties - revue finale',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(
                label: approvalStatus,
                color: _green,
                background: const Color(0xFFEAF7F0),
              ),
              _StatusPill(
                label: isAdminApproved ? 'Approuvé admin' : 'À vérifier',
                color: isAdminApproved ? _green : _amber,
                background: isAdminApproved
                    ? const Color(0xFFEAF7F0)
                    : const Color(0xFFFFF6E5),
              ),
              if (acceptedAt != '--')
                _StatusPill(
                  label: 'Accepté le $acceptedAt',
                  color: _blue,
                  background: const Color(0xFFE9F1FF),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpertCard extends StatelessWidget {
  const _ExpertCard({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.accent = _blue,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRowData {
  const _InfoRowData(this.label, this.value, {this.wide = false});

  final String label;
  final String value;
  final bool wide;
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.rows});

  final List<_InfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 560;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: rows.map((row) {
            final width = !twoColumns || row.wide
                ? constraints.maxWidth
                : (constraints.maxWidth - 10) / 2;
            return SizedBox(
              width: width,
              child: _InfoTile(row: row),
            );
          }).toList(),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.row});

  final _InfoRowData row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _pageBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: _textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            row.value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverSection extends StatelessWidget {
  const _DriverSection({
    required this.driver,
    required this.insurance,
    this.targetInsurance,
  });

  final Map<String, dynamic>? driver;
  final Map<String, dynamic>? insurance;
  final Map<String, dynamic>? targetInsurance;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _InfoRowData('Nom complet', _DetailBody._snap(driver, 'fullName')),
      _InfoRowData('Permis', _DetailBody._snap(driver, 'licenseNumber')),
      _InfoRowData(
        'CIN / Identifiant',
        _DetailBody._snap(driver, 'nationalId'),
      ),
      _InfoRowData('Téléphone', _DetailBody._snap(driver, 'phoneNumber')),
      _InfoRowData(
        'Assurance',
        _DetailBody._snap(insurance, 'insuranceNumber'),
      ),
      _InfoRowData('Compagnie', _DetailBody._snap(insurance, 'companyName')),
      _InfoRowData(
        'Titulaire police',
        _DetailBody._snap(insurance, 'policyHolderName'),
      ),
      _InfoRowData('Type police', _DetailBody._snap(insurance, 'policyType')),
      if (targetInsurance != null)
        _InfoRowData(
          'Assurance cible partie B',
          _DetailBody._snap(targetInsurance, 'insuranceNumber'),
          wide: true,
        ),
    ];

    return _InfoGrid(rows: rows);
  }
}

class _VehiclesSection extends StatelessWidget {
  const _VehiclesSection({required this.vehicleA, required this.vehicleB});

  final Map<String, dynamic>? vehicleA;
  final Map<String, dynamic>? vehicleB;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 620;
        final panels = [
          _VehiclePanel(label: 'Véhicule A', vehicle: vehicleA, color: _blue),
          _VehiclePanel(label: 'Véhicule B', vehicle: vehicleB, color: _green),
        ];

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: panels[0]),
              const SizedBox(width: 12),
              Expanded(child: panels[1]),
            ],
          );
        }

        return Column(
          children: [panels[0], const SizedBox(height: 12), panels[1]],
        );
      },
    );
  }
}

class _VehiclePanel extends StatelessWidget {
  const _VehiclePanel({
    required this.label,
    required this.vehicle,
    required this.color,
  });

  final String label;
  final Map<String, dynamic>? vehicle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _pageBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _KeyValue(
            'Immatriculation',
            _DetailBody._snap(vehicle, 'plateNumber'),
          ),
          _KeyValue('Marque', _DetailBody._snap(vehicle, 'brand')),
          _KeyValue('Modèle', _DetailBody._snap(vehicle, 'model')),
          _KeyValue('VIN', _DetailBody._snap(vehicle, 'vin')),
        ],
      ),
    );
  }
}

class _PhotosDamageSection extends StatelessWidget {
  const _PhotosDamageSection({
    required this.photoScans,
    required this.photoScanIds,
  });

  final List<DocumentScan> photoScans;
  final List<String> photoScanIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (photoScans.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${photoScans.length} photo(s) jointe(s)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: photoScans
                .map((scan) => _AdminPhotoThumbnail(scan: scan))
                .toList(),
          ),
        ],
      );
    }

    if (photoScanIds.isEmpty) {
      return const _MutedNotice(
        icon: Icons.photo_outlined,
        text: "Aucune photo de dégâts n'est liée à ce constat.",
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MutedNotice(
          icon: Icons.info_outline,
          text: 'Aperçu indisponible pour ce constat plus ancien.',
        ),
        const SizedBox(height: 10),
        ...photoScanIds.map(
          (id) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _KeyValue('Photo', id),
          ),
        ),
      ],
    );
  }
}

class _AnalysisCostSection extends StatelessWidget {
  const _AnalysisCostSection({required this.photoScans});

  final List<DocumentScan> photoScans;

  @override
  Widget build(BuildContext context) {
    if (!CostEstimationSummary.hasData(photoScans)) {
      return const _MutedNotice(
        icon: Icons.analytics_outlined,
        text: "Aucune estimation IA exploitable n'est disponible.",
      );
    }

    return CostEstimationSummary(photoScans: photoScans);
  }
}

class _DecisionSection extends StatelessWidget {
  const _DecisionSection({
    required this.approvalStatus,
    required this.requestedInsurance,
    required this.requestedAt,
    required this.ownerUid,
    required this.approverUid,
    required this.adminReviewStatus,
    required this.adminReviewedAt,
    required this.adminReviewedByUid,
    required this.onApprove,
    required this.isApproving,
  });

  final String approvalStatus;
  final String? requestedInsurance;
  final String requestedAt;
  final String? ownerUid;
  final String? approverUid;
  final String? adminReviewStatus;
  final String adminReviewedAt;
  final String? adminReviewedByUid;
  final VoidCallback onApprove;
  final bool isApproving;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoGrid(
          rows: [
            _InfoRowData('Statut parties', approvalStatus),
            _InfoRowData(
              'Assurance demandée',
              _DetailBody._read(requestedInsurance),
            ),
            _InfoRowData('Demande envoyée', requestedAt),
            _InfoRowData('Owner UID', _DetailBody._read(ownerUid)),
            _InfoRowData('Approver UID', _DetailBody._read(approverUid)),
          ],
        ),
        const SizedBox(height: 16),
        _AdminActionSection(
          adminReviewStatus: adminReviewStatus,
          adminReviewedAt: adminReviewedAt,
          adminReviewedByUid: adminReviewedByUid,
          onApprove: onApprove,
          isApproving: isApproving,
        ),
      ],
    );
  }
}

class _AdminActionSection extends StatelessWidget {
  const _AdminActionSection({
    required this.adminReviewStatus,
    required this.adminReviewedAt,
    required this.adminReviewedByUid,
    required this.onApprove,
    required this.isApproving,
  });

  final String? adminReviewStatus;
  final String adminReviewedAt;
  final String? adminReviewedByUid;
  final VoidCallback onApprove;
  final bool isApproving;

  bool get _isApproved => adminReviewStatus == 'approved';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isApproved) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7F0),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _green.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.verified_rounded, color: _green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Constat approuvé',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _green,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (adminReviewedAt != '--')
                    Text(
                      'Approuvé le $adminReviewedAt',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (adminReviewedByUid != null &&
                      adminReviewedByUid!.isNotEmpty)
                    Text(
                      'Par $adminReviewedByUid',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
          : const Icon(Icons.verified_outlined),
      label: Text(
        isApproving ? 'Approbation en cours...' : 'Approuver le constat',
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
      ),
    );
  }
}

class _AdminPhotoThumbnail extends StatelessWidget {
  const _AdminPhotoThumbnail({required this.scan});

  final DocumentScan scan;

  @override
  Widget build(BuildContext context) {
    final url = scan.thumbnailUrl?.isNotEmpty == true
        ? scan.thumbnailUrl!
        : scan.fileUrl;

    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: _pageBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
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
    return const Center(
      child: Icon(Icons.broken_image_outlined, color: _textMuted, size: 30),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: _textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MutedNotice extends StatelessWidget {
  const _MutedNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _pageBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 54, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: _navy),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Retour au tableau de bord'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
