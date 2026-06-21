import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _pageBackground = Color(0xFFF4F7FB);
const _cardBorder = Color(0xFFD8E2EE);
const _navy = Color(0xFF123A63);
const _blue = Color(0xFF1E6BD6);
const _green = Color(0xFF1F8A5B);
const _amber = Color(0xFFB7791F);
const _textMuted = Color(0xFF627387);

class AdminApprovedReportsScreen extends StatefulWidget {
  const AdminApprovedReportsScreen({super.key});

  @override
  State<AdminApprovedReportsScreen> createState() =>
      _AdminApprovedReportsScreenState();
}

class _AdminApprovedReportsScreenState
    extends State<AdminApprovedReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('approved_constats')
          .orderBy('approvalRespondedAt', descending: true)
          .get();

      // Filter locally: only show those where adminReviewStatus == 'approved'
      // This avoids any missing-index issues and is safe for the read-only view.
      final all = snapshot.docs
          .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
          .toList();

      final approved = all
          .where((d) => d['adminReviewStatus'] == 'approved')
          .toList();

      if (mounted) {
        setState(() {
          _reports = approved;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les rapports approuvés.';
          _loading = false;
        });
      }
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
        title: const Text(
          'Rapports approuvés',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: _load,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorView(message: _error!, onRetry: _load)
            : Column(
                children: [
                  _HeaderCard(count: _reports.length),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _reports.isEmpty
                        ? const _EmptyView()
                        : _ReportList(reports: _reports),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Header card ───────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.verified_outlined, color: _green),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rapports approuvés',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Constats validés par l\'administration',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _pageBackground,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _cardBorder),
            ),
            child: Text(
              '$count dossiers',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Report list ───────────────────────────────────────────────────────────────

class _ReportList extends StatelessWidget {
  const _ReportList({required this.reports});

  final List<Map<String, dynamic>> reports;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _ReportCard(data: reports[index]),
    );
  }
}

// ── Report card ───────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final id = _str(data['id']);
    final referenceNumber = _str(data['referenceNumber']).isNotEmpty
        ? _str(data['referenceNumber'])
        : (id.isNotEmpty ? 'Dossier #${id.substring(0, 8)}' : 'Dossier');
    final location = _str(data['accidentLocation']);
    final accidentDate = _fmtDate(data['accidentDateTime'] as String?);
    final partyAName =
        _str((data['driverSnapshot'] as Map?)?['fullName']).isNotEmpty
        ? _str((data['driverSnapshot'] as Map?)?['fullName'])
        : 'Conducteur A';
    final partyBName =
        _str((data['partyBDriverSnapshot'] as Map?)?['fullName']).isNotEmpty
        ? _str((data['partyBDriverSnapshot'] as Map?)?['fullName'])
        : 'Conducteur B';
    final estimatedCost = _extractCost(data);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: id.isNotEmpty
            ? () => context.push(RouteNames.adminConstatDetailPath(id))
            : null,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // — Header row: reference + Approuvé badge ——————————————
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      referenceNumber,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: _navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7F0),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _green.withValues(alpha: 0.24)),
                    ),
                    child: const Text(
                      'Approuvé',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: _green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // — Meta lines ——————————————————————————————————————————
              if (location.isNotEmpty)
                _MetaLine(icon: Icons.location_on_outlined, text: location),
              if (accidentDate.isNotEmpty)
                _MetaLine(
                  icon: Icons.event_outlined,
                  text: 'Accident : $accidentDate',
                ),
              const SizedBox(height: 10),

              // — Party box ———————————————————————————————————————————
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _pageBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cardBorder),
                ),
                child: Column(
                  children: [
                    _PartyRow(letter: 'A', name: partyAName, color: _blue),
                    const SizedBox(height: 6),
                    _PartyRow(letter: 'B', name: partyBName, color: _green),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // — Footer: cost + open button —————————————————————————
              Row(
                children: [
                  Expanded(
                    child: estimatedCost != null
                        ? _CostPill(value: estimatedCost)
                        : const Text(
                            'Coût estimé non disponible',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _textMuted,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  if (id.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () =>
                          context.push(RouteNames.adminConstatDetailPath(id)),
                      style: FilledButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text(
                        'Voir le dossier',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _str(dynamic v) {
    final s = v?.toString().trim();
    return s == null || s.isEmpty ? '' : s;
  }

  static String _fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  static String? _extractCost(Map<String, dynamic> data) {
    final scans = data['photoScansSnapshot'];
    if (scans is! List) return null;
    double total = 0;
    for (final scan in scans) {
      if (scan is! Map) continue;
      final extracted = scan['extractedData'];
      if (extracted is! Map) continue;
      final cost = extracted['costEstimation'];
      if (cost is! Map) continue;
      final value = _toDouble(cost['recommendedTotal']);
      if (value != null && value > 0) total += value;
    }
    if (total <= 0) return null;
    return '${NumberFormat.decimalPattern('fr').format(total.round())} TND';
  }

  static double? _toDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartyRow extends StatelessWidget {
  const _PartyRow({
    required this.letter,
    required this.name,
    required this.color,
  });

  final String letter;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            letter,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: color,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
        ),
      ],
    );
  }
}

class _CostPill extends StatelessWidget {
  const _CostPill({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _green.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payments_outlined, size: 15, color: _green),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: _green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty / Error views ───────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 52, color: _textMuted),
          SizedBox(height: 12),
          Text(
            'Aucun rapport approuvé pour le moment.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: _amber),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _navy,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: _navy),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
