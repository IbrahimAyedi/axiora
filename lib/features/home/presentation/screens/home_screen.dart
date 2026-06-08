import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_constants.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/constat.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/providers/notifications_provider.dart';

// home screen principale
// yبدل contenu حسب user normal wala admin
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // theme mte3 app
    final theme = Theme.of(context);

    // true ken dark mode
    final isDark = theme.brightness == Brightness.dark;

    // session state: user, constats, scans...
    final session = ref.watch(appSessionProvider);

    // notifications state bech nجيبوا unread count
    final notificationsState = ref.watch(notificationsProvider);

    // debug log bech nراقبو unread notifications
    debugPrint(
      'HomeScreen.build() - unreadCount: ${notificationsState.unreadCount}',
    );

    // true ken user admin
    final isAdmin = session.currentUser.isAdmin;

    // user name lel greeting
    final userName = session.currentUser.fullName ?? 'User';

    // first letter lel avatar
    final firstLetter = userName.isEmpty
        ? 'U'
        : userName.substring(0, 1).toUpperCase();

    // nombre mte3 draft constats
    final draftCount = session.constats
        .where((constat) => constat.status.name == 'draft')
        .length;

    // Shared AppBar actions (notifications bell + avatar)
    // actions mte3 appbar: notifications w profile avatar
    final appBarActions = [
      // notification bell
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push(RouteNames.notificationsPath),
            ),

            // badge mte3 unread notifications
            if (notificationsState.unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    notificationsState.unreadCount > 9
                        ? '9+'
                        : '${notificationsState.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),

      // avatar yemchi lel profile
      Padding(
        padding: const EdgeInsets.only(right: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push(RouteNames.profilePath),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: isDark
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : const Color(0xFFE7F0FB),
            child: Text(
              firstLetter,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isDark
                    ? theme.colorScheme.primary
                    : const Color(0xFF124170),
              ),
            ),
          ),
        ),
      ),
    ];

    return Scaffold(
      // appbar mte3 home
      appBar: AppBar(
        title: Text(AppConstants.appName, style: theme.textTheme.titleMedium),
        actions: appBarActions,
      ),

      // body يتبدل حسب role
      body: SafeArea(
        child: isAdmin
            ? _AdminHomeBody(userName: userName, theme: theme)
            : _UserHomeBody(
                session: session,
                theme: theme,
                isDark: isDark,
                userName: userName,
                draftCount: draftCount,
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Admin home body
// ---------------------------------------------------------------------------

// body mte3 admin home
class _AdminHomeBody extends StatelessWidget {
  const _AdminHomeBody({required this.userName, required this.theme});

  // esm admin
  final String userName;

  // theme mte3 app
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Admin header banner
        // header special lel admin
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3A006F), Color(0xFF6A1B9A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // admin badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 13,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // greeting lel admin
              Text(
                'Hello, $userName',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              // description mte3 admin role
              Text(
                'Review accepted constats and insurance reports.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha(200),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // actions section
        const _SectionHeader(label: 'Actions'),
        const SizedBox(height: 12),

        // card yemchi lel admin dashboard
        _DashboardActionCard(
          title: 'Admin dashboard',
          subtitle: 'View platform statistics and accepted constats.',
          icon: Icons.admin_panel_settings_outlined,
          accentColor: const Color(0xFF6A1B9A),
          chipLabel: 'Admin',
          onTap: () => context.push(RouteNames.adminDashboardPath),
        ),
        const SizedBox(height: 28),

        // more section
        const _SectionHeader(label: 'More'),
        const SizedBox(height: 12),

        // settings w about
        Row(
          children: [
            Expanded(
              child: _SecondaryActionTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () => context.push(RouteNames.settingsPath),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SecondaryActionTile(
                icon: Icons.info_outline,
                title: 'About',
                onTap: () => context.push(RouteNames.aboutPath),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Normal user home body (unchanged logic)
// ---------------------------------------------------------------------------

// body mte3 user normal
class _UserHomeBody extends StatelessWidget {
  const _UserHomeBody({
    required this.session,
    required this.theme,
    required this.isDark,
    required this.userName,
    required this.draftCount,
  });

  // session state
  final AppSessionState session;

  // theme mte3 app
  final ThemeData theme;

  // true ken dark mode
  final bool isDark;

  // esm user
  final String userName;

  // nombre drafts
  final int draftCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // user header banner
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F3459), Color(0xFF1A5C96)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // greeting
              Text(
                'Hello, $userName',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              // description
              Text(
                'Create and manage your accident reports.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha(200),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // stats: scans w drafts
              Row(
                children: [
                  _StatChip(
                    icon: Icons.document_scanner_outlined,
                    label: '${session.scans.length} scans',
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.task_alt_outlined,
                    label: '$draftCount draft${draftCount == 1 ? '' : 's'}',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ken fama active draft, nwarriw continue draft card
        if (session.activeConstat != null &&
            session.activeConstat!.status == ConstatStatus.draft) ...[
          const _SectionHeader(label: 'Continue your draft'),
          const SizedBox(height: 12),
          _ActiveDraftCard(constat: session.activeConstat!),
          const SizedBox(height: 28),
        ],

        // quick actions
        const _SectionHeader(label: 'Quick actions'),
        const SizedBox(height: 12),

        // start new constat
        _DashboardActionCard(
          title: 'Start new constat',
          subtitle: 'Create a guided accident report with OCR documents.',
          icon: Icons.assignment_outlined,
          accentColor: const Color(0xFFF9A825),
          chipLabel: 'Report',
          onTap: () => context.push(RouteNames.constatIntroPath),
        ),
        const SizedBox(height: 10),

        // history
        _DashboardActionCard(
          title: 'History',
          subtitle: 'Review your saved drafts and reports.',
          icon: Icons.history_rounded,
          accentColor: const Color(0xFF2E7D32),
          chipLabel: 'Archive',
          onTap: () => context.push(RouteNames.historyPath),
        ),
        const SizedBox(height: 28),

        // more section
        const _SectionHeader(label: 'More'),
        const SizedBox(height: 12),

        // settings w about
        Row(
          children: [
            Expanded(
              child: _SecondaryActionTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () => context.push(RouteNames.settingsPath),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SecondaryActionTile(
                icon: Icons.info_outline,
                title: 'About',
                onTap: () => context.push(RouteNames.aboutPath),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// title sghir mte3 section
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  // text mte3 section
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// card action principale fi dashboard
class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.chipLabel,
  });

  // title mte3 card
  final String title;

  // subtitle mte3 card
  final String subtitle;

  // icon mte3 action
  final IconData icon;

  // couleur principale
  final Color accentColor;

  // action ki user yenzel 3la card
  final VoidCallback onTap;

  // chip label optionnel
  final String? chipLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // true ken dark mode
    final isDark = theme.brightness == Brightness.dark;

    // colors حسب theme
    final cardColor = isDark ? theme.colorScheme.surface : Colors.white;
    final borderColor = isDark
        ? theme.colorScheme.outline.withValues(alpha: 0.3)
        : const Color(0xFFD7E0EA);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // icon box
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.2 : 0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),

              // title/subtitle/chip
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // card title
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),

                        // chip optional
                        if (chipLabel != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(
                                alpha: isDark ? 0.25 : 0.07,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              chipLabel!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),

                    // card subtitle
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // arrow icon
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// tile secondaire kif settings/about
class _SecondaryActionTile extends StatelessWidget {
  const _SecondaryActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  // icon mte3 tile
  final IconData icon;

  // title mte3 tile
  final String title;

  // action ki user yenzel
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // true ken dark mode
    final isDark = theme.brightness == Brightness.dark;

    // colors حسب theme
    final cardColor = isDark ? theme.colorScheme.surface : Colors.white;
    final borderColor = isDark
        ? theme.colorScheme.outline.withValues(alpha: 0.3)
        : const Color(0xFFD7E0EA);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // icon
              Icon(
                icon,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 10),

              // title
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// chip sghira taffichi stat fi header
class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  // icon mte3 stat
  final IconData icon;

  // label mte3 stat
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // icon
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),

          // label
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withAlpha(220),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// card mte3 active draft
class _ActiveDraftCard extends ConsumerWidget {
  const _ActiveDraftCard({required this.constat});

  // active draft constat
  final Constat constat;

  void _showDiscardDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard this draft?'),
        content: const Text(
          'This will remove the current draft from your active draft list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep draft'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(appSessionProvider.notifier).discardActiveDraft();
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // true ken dark mode
    final isDark = theme.brightness == Brightness.dark;

    // n7sbou wa9teh last updated
    final now = DateTime.now();
    final updatedAt = constat.updatedAt;
    final difference = now.difference(updatedAt);

    // Format time ago
    // nformatou updatedAt b time ago
    String timeAgo;
    if (difference.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      timeAgo =
          '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      timeAgo =
          '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }

    // Determine current step based on what's filled
    // nحددou next step حسب chnowa t3abba fil draft
    String currentStep;
    String nextRoute;
    if (constat.driverSnapshot == null) {
      currentStep = 'Step 2 of 8 - Driver information';
      nextRoute = RouteNames.driverInfoPath;
    } else if (constat.vehicleSnapshot == null) {
      currentStep = 'Step 3 of 8 - Vehicle information';
      nextRoute = RouteNames.vehicleInfoPath;
    } else if (((constat.partyAInsuranceSnapshot?['insuranceNumber'] as String?)
                ?.isNotEmpty !=
            true) &&
        ((constat.insuranceSnapshot?['insuranceNumber'] as String?)
                ?.isNotEmpty !=
            true)) {
      currentStep = 'Step 4 of 8 - Insurance information';
      nextRoute = RouteNames.insuranceInfoPath;
    } else if (constat.photoScanIds.isEmpty) {
      currentStep = 'Step 5 of 8 - Photos and damage';
      nextRoute = RouteNames.photosDamagePath;
    } else {
      currentStep = 'Step 6 of 8 - Review';
      nextRoute = RouteNames.constatReviewPath;
    }

    // Colors that adapt to theme
    // colors حسب theme
    final cardColor = isDark
        ? theme.colorScheme.surface
        : const Color(0xFFFFF8E1);
    final borderColor = isDark
        ? theme.colorScheme.outline.withValues(alpha: 0.3)
        : const Color(0xFFFBC02D).withValues(alpha: 0.4);
    final accentColor = const Color(0xFFF9A825);
    final iconBgColor = isDark
        ? accentColor.withValues(alpha: 0.2)
        : accentColor.withValues(alpha: 0.08);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // status w updated time
            Row(
              children: [
                // in progress badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'IN PROGRESS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),

                // time ago
                Text(
                  timeAgo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // draft reference w current step
            Row(
              children: [
                // icon box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.assignment_outlined,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // reference number w step
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // reference
                      Text(
                        constat.referenceNumber,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // current step
                      Text(
                        currentStep,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // action buttons: discard (left) + continue (right)
            Row(
              children: [
                // discard draft — subtle danger text button
                TextButton(
                  onPressed: () => _showDiscardDialog(context, ref),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Discard draft'),
                ),
                const SizedBox(width: 8),

                // continue — primary amber button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(nextRoute),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
