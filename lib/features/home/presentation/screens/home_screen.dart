import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/models/constat.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/providers/notifications_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider);
    final notificationsState = ref.watch(notificationsProvider);

    debugPrint(
      'HomeScreen.build() - unreadCount: ${notificationsState.unreadCount}',
    );

    final isAdmin = session.currentUser.isAdmin;
    final fullName = session.currentUser.fullName ?? 'Utilisateur';
    final firstName = fullName.split(' ').first;
    final firstLetter = firstName.isEmpty ? 'U' : firstName[0].toUpperCase();

    // Constat counts — computed locally, no new backend calls
    final draftCount = session.constats
        .where((c) => c.status == ConstatStatus.draft)
        .length;
    final pendingCount = session.constats
        .where(
          (c) =>
              c.status == ConstatStatus.submitted &&
              c.approvalStatus == 'pending',
        )
        .length;
    final acceptedCount = session.constats
        .where((c) => c.approvalStatus == 'accepted')
        .length;
    final approvedCount = session.constats
        .where((c) => c.adminReviewStatus == 'approved')
        .length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _GreetingHeader(
                firstName: firstName,
                firstLetter: firstLetter,
                unreadCount: notificationsState.unreadCount,
                isAdmin: isAdmin,
              ),
              Expanded(
                child: isAdmin
                    ? const _AdminHomeBody()
                    : _UserHomeBody(
                        session: session,
                        draftCount: draftCount,
                        pendingCount: pendingCount,
                        acceptedCount: acceptedCount,
                        approvedCount: approvedCount,
                        notificationsState: notificationsState,
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _HomeBottomNav(
          unreadCount: notificationsState.unreadCount,
          isAdmin: isAdmin,
        ),
      ),
    );
  }
}

// ── Compact greeting header ──────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.firstName,
    required this.firstLetter,
    required this.unreadCount,
    required this.isAdmin,
  });

  final String firstName;
  final String firstLetter;
  final int unreadCount;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, $firstName 👋',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAdmin ? 'Espace administrateur' : 'Votre tableau de bord',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primary,
                ),
                onPressed: () => context.push(RouteNames.notificationsPath),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.push(RouteNames.profilePath),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                firstLetter,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.trustBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Primary "Nouveau constat" card ───────────────────────────────────────────

class _NewConstatCard extends StatelessWidget {
  const _NewConstatCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.constatIntroPath),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1769AA), Color(0xFF0B2D4D)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B2D4D).withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nouveau constat',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Déclarez un accident en quelques étapes.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mes constats summary card ────────────────────────────────────────────────

class _MesConstatsCard extends StatelessWidget {
  const _MesConstatsCard({
    required this.draftCount,
    required this.pendingCount,
    required this.acceptedCount,
    required this.approvedCount,
  });

  final int draftCount;
  final int pendingCount;
  final int acceptedCount;
  final int approvedCount;

  @override
  Widget build(BuildContext context) {
    final total = draftCount + pendingCount + acceptedCount + approvedCount;

    return GestureDetector(
      onTap: () => context.push(RouteNames.historyPath),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Row(
                children: [
                  const Text(
                    'Mes constats',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  if (total > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Text(
                        '$total au total',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.trustBlue,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 18, endIndent: 18),
            _StatusRow(
              icon: Icons.pending_actions_outlined,
              label: 'En cours',
              count: draftCount,
              iconColor: Color(0xFFF59E0B),
            ),
            const Divider(height: 1, indent: 54, endIndent: 18),
            _StatusRow(
              icon: Icons.hourglass_top_outlined,
              label: 'En attente conducteur B',
              count: pendingCount,
              iconColor: AppColors.trustBlue,
            ),
            const Divider(height: 1, indent: 54, endIndent: 18),
            _StatusRow(
              icon: Icons.check_circle_outline_rounded,
              label: 'Acceptés',
              count: acceptedCount,
              iconColor: AppColors.success,
            ),
            const Divider(height: 1, indent: 54, endIndent: 18),
            _StatusRow(
              icon: Icons.verified_outlined,
              label: 'Approuvés / Terminés',
              count: approvedCount,
              iconColor: AppColors.primary,
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mes documents card ───────────────────────────────────────────────────────

class _MesDocumentsCard extends StatelessWidget {
  const _MesDocumentsCard({required this.scanCount});

  final int scanCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.scanPath),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.document_scanner_outlined,
                size: 22,
                color: AppColors.trustBlue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mes documents',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Documents OCR et photos ajoutés',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Text(
                '$scanCount scan${scanCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.trustBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notifications preview card ───────────────────────────────────────────────

class _NotificationsPreviewCard extends StatelessWidget {
  const _NotificationsPreviewCard({required this.notificationsState});

  final NotificationsState notificationsState;

  @override
  Widget build(BuildContext context) {
    final notifications = notificationsState.notifications;
    final latest = notifications.isNotEmpty ? notifications.first : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
            child: Row(
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push(RouteNames.notificationsPath),
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.trustBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          const Divider(height: 1, indent: 18, endIndent: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: latest == null
                ? const Row(
                    children: [
                      Icon(
                        Icons.notifications_none_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Vous n\'avez aucune notification récente.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.notifications_outlined,
                          size: 18,
                          color: AppColors.trustBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              latest.title,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              latest.body,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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

// ── Quick link tile ──────────────────────────────────────────────────────────

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: AppColors.trustBlue),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── User home body ───────────────────────────────────────────────────────────

class _UserHomeBody extends StatelessWidget {
  const _UserHomeBody({
    required this.session,
    required this.draftCount,
    required this.pendingCount,
    required this.acceptedCount,
    required this.approvedCount,
    required this.notificationsState,
  });

  final AppSessionState session;
  final int draftCount;
  final int pendingCount;
  final int acceptedCount;
  final int approvedCount;
  final NotificationsState notificationsState;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      children: [
        const _NewConstatCard(),
        const SizedBox(height: 14),

        if (session.activeConstat != null &&
            session.activeConstat!.status == ConstatStatus.draft) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ActiveDraftCard(constat: session.activeConstat!),
          ),
          const SizedBox(height: 14),
        ],

        _MesConstatsCard(
          draftCount: draftCount,
          pendingCount: pendingCount,
          acceptedCount: acceptedCount,
          approvedCount: approvedCount,
        ),
        const SizedBox(height: 14),

        _MesDocumentsCard(scanCount: session.scans.length),
        const SizedBox(height: 14),

        _NotificationsPreviewCard(notificationsState: notificationsState),
        const SizedBox(height: 14),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _QuickTile(
                  icon: Icons.settings_outlined,
                  label: 'Paramètres',
                  onTap: () => context.push(RouteNames.settingsPath),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickTile(
                  icon: Icons.info_outline_rounded,
                  label: 'À propos',
                  onTap: () => context.push(RouteNames.aboutPath),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Profil',
                  onTap: () => context.push(RouteNames.profilePath),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Admin home body ──────────────────────────────────────────────────────────

class _AdminHomeBody extends StatelessWidget {
  const _AdminHomeBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () => context.push(RouteNames.adminDashboardPath),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF071D33), Color(0xFF1769AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B2D4D).withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tableau de bord admin',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Consulter les constats en attente d\'approbation.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.80),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _AdminQuickTile(
                  icon: Icons.folder_open_rounded,
                  label: 'Dossiers à examiner',
                  accentColor: AppColors.warning,
                  onTap: () => context.push(RouteNames.adminDashboardPath),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AdminQuickTile(
                  icon: Icons.people_alt_outlined,
                  label: 'Utilisateurs',
                  accentColor: AppColors.trustBlue,
                  onTap: () => context.push(RouteNames.adminUsersPath),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AdminQuickTile(
                  icon: Icons.verified_rounded,
                  label: 'Rapports approuvés',
                  accentColor: AppColors.success,
                  onTap: () =>
                      context.push(RouteNames.adminApprovedReportsPath),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Admin quick tile (role-specific variant) ─────────────────────────────────

class _AdminQuickTile extends StatelessWidget {
  const _AdminQuickTile({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: accentColor),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom navigation bar ────────────────────────────────────────────────────

class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({required this.unreadCount, required this.isAdmin});

  final int unreadCount;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x140B2D4D),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: isAdmin
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Accueil',
                      isSelected: true,
                      onTap: () {},
                    ),
                    _NavItem(
                      icon: Icons.people_alt_outlined,
                      activeIcon: Icons.people_alt,
                      label: 'Utilisateurs',
                      onTap: () => context.push(RouteNames.adminUsersPath),
                    ),
                    _NavItem(
                      icon: Icons.notifications_outlined,
                      activeIcon: Icons.notifications,
                      label: 'Alertes',
                      badge: unreadCount,
                      onTap: () => context.push(RouteNames.notificationsPath),
                    ),
                    _NavItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Profil',
                      onTap: () => context.push(RouteNames.profilePath),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Accueil',
                      isSelected: true,
                      onTap: () {},
                    ),
                    _NavItem(
                      icon: Icons.assignment_outlined,
                      activeIcon: Icons.assignment,
                      label: 'Constats',
                      onTap: () => context.push(RouteNames.historyPath),
                    ),
                    _NavItem(
                      icon: Icons.document_scanner_outlined,
                      activeIcon: Icons.document_scanner,
                      label: 'Scanner',
                      onTap: () => context.push(RouteNames.scanPath),
                    ),
                    _NavItem(
                      icon: Icons.notifications_outlined,
                      activeIcon: Icons.notifications,
                      label: 'Alertes',
                      badge: unreadCount,
                      onTap: () => context.push(RouteNames.notificationsPath),
                    ),
                    _NavItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Profil',
                      onTap: () => context.push(RouteNames.profilePath),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.badge = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isSelected ? activeIcon : icon, size: 24, color: color),
                if (badge > 0)
                  Positioned(
                    right: -5,
                    top: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Active draft card (business logic unchanged) ─────────────────────────────

class _ActiveDraftCard extends ConsumerWidget {
  const _ActiveDraftCard({required this.constat});

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

    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final updatedAt = constat.updatedAt;
    final difference = now.difference(updatedAt);

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
            Row(
              children: [
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
                Text(
                  timeAgo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        constat.referenceNumber,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
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

            Row(
              children: [
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
