import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_names.dart';

// screen mte3 admin dashboard
// ywarri platform statistics w liste mte3 accepted constats
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // liste mte3 constats accepted jeya mel approved_constats
  List<Map<String, dynamic>> _constats = [];

  // nombre total mte3 users
  int _userCount = 0;

  // loading state
  bool _loading = true;

  // error message ken fama problem
  String? _error;

  @override
  void initState() {
    super.initState();

    // ki screen tet7al, nloadiw data mte3 dashboard
    _load();
  }

  // tloadi approved constats w users count mel Firestore
  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      // Load approved_constats and users count in parallel
      // nloadiw constats accepted w users fi nafs wa9t
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('approved_constats')
            .orderBy('approvalRespondedAt', descending: true)
            .get(),
        FirebaseFirestore.instance.collection('users').get(),
      ]);

      // result lowel fih approved_constats
      final constatSnapshot = results[0];

      // result theni fih users
      final usersSnapshot = results[1];

      // n7awlou docs l list mte3 maps w nzidou id mte3 document
      final constats = constatSnapshot.docs
          .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
          .toList();

      // nupdatew state ken widget mazal mounted
      if (mounted) {
        setState(() {
          _constats = constats;
          _userCount = usersSnapshot.docs.length;
          _loading = false;
        });
      }
    } catch (e) {
      // ken fama error fi Firestore
      if (mounted) {
        setState(() {
          _error = 'Failed to load dashboard data: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // true ken app fi dark mode
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // appbar mte3 dashboard
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Dashboard'),
            Text('Platform overview', style: theme.textTheme.bodySmall),
          ],
        ),
        actions: [
          // button refresh ya3awed yloadi data
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),

      // body mte3 screen
      body: SafeArea(
        child: _loading
            // loading indicator
            ? const Center(child: CircularProgressIndicator())

            // error view ken fama problem
            : _error != null
            ? _ErrorView(message: _error!, onRetry: _load)

            // content mte3 dashboard
            : RefreshIndicator(
                // pull to refresh
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    // ── Stats cards ───────────────────────────────────────
                    // section mte3 platform statistics
                    _SectionLabel(label: 'Platform statistics', theme: theme),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // card mte3 total users
                        Expanded(
                          child: _StatCard(
                            icon: Icons.people_outline,
                            label: 'Total users',
                            value: '$_userCount',
                            color: const Color(0xFF1565C0),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // card mte3 approved constats
                        Expanded(
                          child: _StatCard(
                            icon: Icons.check_circle_outline,
                            label: 'Approved constats',
                            value: '${_constats.length}',
                            color: const Color(0xFF2E7D32),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Pending / rejected note
                    // note tفسر eli pending/rejected mahomech tracked globally
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.surface
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 15,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pending and rejected constats are stored per-user '
                              'and not tracked globally in this version.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Constat list ──────────────────────────────────────
                    // section mte3 latest accepted constats
                    _SectionLabel(
                      label: 'Latest accepted constats',
                      theme: theme,
                    ),
                    const SizedBox(height: 12),

                    // ken ma famech accepted constats
                    if (_constats.isEmpty)
                      _EmptyView(isDark: isDark)

                    // sinon nwarriw liste mte3 accepted constats
                    else
                      ...List.generate(_constats.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ApprovedConstatCard(
                            data: _constats[index],
                            isDark: isDark,
                            onTap: () {
                              // ki admin yenzel 3la card, nemchiw lel detail screen
                              final id =
                                  _constats[index]['id'] as String? ?? '';
                              context.push(
                                RouteNames.adminConstatDetailPath(id),
                              );
                            },
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat card
// ---------------------------------------------------------------------------

// widget ywarri statistic card
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  // icon mte3 stat
  final IconData icon;

  // label mte3 stat
  final String label;

  // value mte3 stat
  final String value;

  // couleur principale mte3 card
  final Color color;

  // true ken dark mode
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // background color حسب theme
    final bg = isDark ? theme.colorScheme.surface : Colors.white;

    // border color حسب theme
    final borderColor = isDark
        ? theme.colorScheme.outline.withValues(alpha: 0.25)
        : const Color(0xFFD7E0EA);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // icon box
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),

          // value mte3 statistic
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),

          // label mte3 statistic
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Constat list card
// ---------------------------------------------------------------------------

// card mte3 constat accepted fi admin list
class _ApprovedConstatCard extends StatelessWidget {
  const _ApprovedConstatCard({
    required this.data,
    required this.isDark,
    required this.onTap,
  });

  // data mte3 constat
  final Map<String, dynamic> data;

  // true ken dark mode
  final bool isDark;

  // action ki admin yenzel 3la card
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // colors حسب theme
    final cardColor = isDark ? theme.colorScheme.surface : Colors.white;
    final borderColor = isDark
        ? theme.colorScheme.outline.withValues(alpha: 0.3)
        : const Color(0xFFD7E0EA);

    // basic data mte3 constat
    final referenceNumber = data['referenceNumber'] as String? ?? '--';
    final location = data['accidentLocation'] as String?;
    final accidentDateRaw = data['accidentDateTime'] as String?;
    final respondedAtRaw = data['approvalRespondedAt'] as String?;

    // names mte3 Party A w Party B
    final partyAName =
        (data['driverSnapshot'] as Map?)?['fullName'] as String? ?? '--';
    final partyBName =
        (data['partyBDriverSnapshot'] as Map?)?['fullName'] as String? ?? '--';

    // formatted dates
    final accidentDate = accidentDateRaw != null
        ? _fmtDate(accidentDateRaw)
        : null;
    final acceptedDate = respondedAtRaw != null
        ? _fmtDate(respondedAtRaw)
        : null;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // status badge + arrow
              Row(
                children: [
                  // Status badge
                  // badge accepted
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 13,
                          color: isDark
                              ? Colors.green.shade300
                              : Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ACCEPTED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.green.shade300
                                : Colors.green.shade700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // arrow lel detail
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // reference number
              Text(
                referenceNumber,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              // accident location
              if (location != null) ...[
                _Meta(
                  icon: Icons.location_on_outlined,
                  text: location,
                  theme: theme,
                ),
                const SizedBox(height: 4),
              ],

              // accident date
              if (accidentDate != null) ...[
                _Meta(
                  icon: Icons.event_outlined,
                  text: 'Accident: $accidentDate',
                  theme: theme,
                ),
                const SizedBox(height: 4),
              ],

              // Party A name
              _Meta(
                icon: Icons.person_outline,
                text: 'Party A: $partyAName',
                theme: theme,
              ),
              const SizedBox(height: 4),

              // Party B name
              _Meta(
                icon: Icons.person_outline,
                text: 'Party B: $partyBName',
                theme: theme,
              ),

              // accepted date
              if (acceptedDate != null) ...[
                const SizedBox(height: 4),
                _Meta(
                  icon: Icons.task_alt,
                  text: 'Accepted: $acceptedDate',
                  theme: theme,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // tformat date string l yyyy-MM-dd HH:mm
  static String _fmtDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }
}

// row sghira mte3 metadata fi card
class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, required this.theme});

  // icon mte3 meta info
  final IconData icon;

  // text mte3 meta info
  final String text;

  // theme mte3 app
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // icon
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 6),

        // text
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

// title sghir mte3 section
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.theme});

  // label mte3 section
  final String label;

  // theme mte3 app
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / error states
// ---------------------------------------------------------------------------

// widget yban ki ma famech accepted constats
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.isDark});

  // true ken dark mode
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // empty icon
          Icon(
            Icons.inbox_outlined,
            size: 56,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),

          // empty title
          Text(
            'No accepted constats yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),

          // empty description
          Text(
            'Constats accepted by both parties will appear here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

// widget yban ken dashboard loading failed
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  // error message
  final String message;

  // function retry
  final VoidCallback onRetry;

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

            // error text
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // retry button
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}