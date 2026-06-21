import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';

const _pageBackground = Color(0xFFF4F7FB);
const _cardBorder = Color(0xFFD8E2EE);
const _navy = Color(0xFF123A63);
const _blue = Color(0xFF1E6BD6);
const _green = Color(0xFF1F8A5B);
const _amber = Color(0xFFB7791F);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Map<String, dynamic>> _constats = [];
  int _userCount = 0;
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
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('approved_constats')
            .orderBy('approvalRespondedAt', descending: true)
            .get(),
        FirebaseFirestore.instance.collection('users').get(),
      ]);

      final constatSnapshot = results[0];
      final usersSnapshot = results[1];
      final constats = constatSnapshot.docs
          .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
          .toList();

      if (mounted) {
        setState(() {
          _constats = constats;
          _userCount = usersSnapshot.docs.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger le tableau de bord: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _constats
        .where((c) => c['adminReviewStatus'] != 'approved')
        .length;
    final approvedCount = _constats
        .where((c) => c['adminReviewStatus'] == 'approved')
        .length;
    final todayCount = _constats.where(_isAcceptedToday).length;

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _navy,
        title: const Text(
          'Tableau de bord admin',
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
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                  children: [
                    _DashboardHeader(
                      totalConstats: _constats.length,
                      userCount: _userCount,
                    ),
                    const SizedBox(height: 18),
                    _StatsGrid(
                      pendingCount: pendingCount,
                      approvedCount: approvedCount,
                      todayCount: todayCount,
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        const Expanded(
                          child: _SectionTitle(
                            title: 'Constats acceptés à vérifier',
                            subtitle: 'Dossiers prêts pour revue expert',
                          ),
                        ),
                        _CountPill(label: '${_constats.length} dossiers'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_constats.isEmpty)
                      const _EmptyView()
                    else
                      ..._constats.map(
                        (data) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ApprovedConstatCard(
                            data: data,
                            onTap: () {
                              final id = data['id'] as String? ?? '';
                              context.push(
                                RouteNames.adminConstatDetailPath(id),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  static bool _isAcceptedToday(Map<String, dynamic> data) {
    final raw = data['approvalRespondedAt'] as String?;
    if (raw == null || raw.isEmpty) return false;
    final date = DateTime.tryParse(raw);
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.totalConstats,
    required this.userCount,
  });

  final int totalConstats;
  final int userCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
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
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F1FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.admin_panel_settings, color: _blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tableau de bord admin',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: _navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Constats acceptés à vérifier',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF52677C),
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
              _HeaderChip(
                icon: Icons.assignment_turned_in_outlined,
                label: '$totalConstats dossiers acceptés',
              ),
              _HeaderChip(
                icon: Icons.people_alt_outlined,
                label: '$userCount utilisateurs',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _pageBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _blue),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.pendingCount,
    required this.approvedCount,
    required this.todayCount,
  });

  final int pendingCount;
  final int approvedCount;
  final int todayCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        final cards = [
          _StatCard(
            icon: Icons.pending_actions_outlined,
            label: 'En attente de validation',
            value: pendingCount.toString(),
            accent: _amber,
            tint: const Color(0xFFFFF6E5),
          ),
          _StatCard(
            icon: Icons.verified_outlined,
            label: 'Approuvés',
            value: approvedCount.toString(),
            accent: _green,
            tint: const Color(0xFFEAF7F0),
          ),
          _StatCard(
            icon: Icons.today_outlined,
            label: "Aujourd'hui",
            value: todayCount.toString(),
            accent: _blue,
            tint: const Color(0xFFE9F1FF),
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              cards[i],
            ],
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: _navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF52677C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovedConstatCard extends StatelessWidget {
  const _ApprovedConstatCard({required this.data, required this.onTap});

  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final referenceNumber = _read(data['referenceNumber'], fallback: 'Dossier');
    final location = _read(data['accidentLocation']);
    final accidentDate = _fmtDate(data['accidentDateTime'] as String?);
    final acceptedDate = _fmtDate(data['approvalRespondedAt'] as String?);
    final partyAName = _read(
      (data['driverSnapshot'] as Map?)?['fullName'],
      fallback: 'Conducteur A',
    );
    final partyBName = _read(
      (data['partyBDriverSnapshot'] as Map?)?['fullName'],
      fallback: 'Conducteur B',
    );
    final isFinalApproved = data['adminReviewStatus'] == 'approved';
    final estimatedCost = _extractEstimatedCost(data);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          referenceNumber,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: _navy,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (location != '--')
                          _MetaLine(
                            icon: Icons.location_on_outlined,
                            text: location,
                          ),
                        if (accidentDate != '--')
                          _MetaLine(
                            icon: Icons.event_outlined,
                            text: 'Accident: $accidentDate',
                          ),
                        if (acceptedDate != '--')
                          _MetaLine(
                            icon: Icons.task_alt_outlined,
                            text: 'Accepté: $acceptedDate',
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusBadge(
                    label: isFinalApproved ? 'Approuvé' : 'À vérifier',
                    color: isFinalApproved ? _green : _amber,
                    background: isFinalApproved
                        ? const Color(0xFFEAF7F0)
                        : const Color(0xFFFFF6E5),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _pageBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _cardBorder),
                ),
                child: Column(
                  children: [
                    _PartyLine(label: 'A', name: partyAName, color: _blue),
                    const SizedBox(height: 8),
                    _PartyLine(label: 'B', name: partyBName, color: _green),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: estimatedCost == null
                        ? Text(
                            'Coût estimé non disponible',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7D90),
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : _CostPill(value: estimatedCost),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.manage_search_outlined, size: 18),
                    label: const Text(
                      'Examiner',
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

  static String _read(Object? value, {String fallback = '--'}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  static String _fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) return '--';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  static String? _extractEstimatedCost(Map<String, dynamic> data) {
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

class _PartyLine extends StatelessWidget {
  const _PartyLine({
    required this.label,
    required this.name,
    required this.color,
  });

  final String label;
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
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF6B7D90)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF52677C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
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

class _CostPill extends StatelessWidget {
  const _CostPill({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payments_outlined, size: 17, color: _green),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _green,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: _navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF6B7D90),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _cardBorder),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: _navy,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F1FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.fact_check_outlined, color: _blue),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun constat à examiner',
            style: theme.textTheme.titleMedium?.copyWith(
              color: _navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les constats acceptés par les deux parties apparaîtront ici.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7D90),
              fontWeight: FontWeight.w600,
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
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
