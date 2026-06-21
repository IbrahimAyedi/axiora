import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ── Palette shared with other admin screens ──────────────────────────────────
const _pageBackground = Color(0xFFF4F7FB);
const _cardBorder = Color(0xFFD8E2EE);
const _navy = Color(0xFF123A63);
const _blue = Color(0xFF1E6BD6);
const _green = Color(0xFF1F8A5B);
const _amber = Color(0xFFB7791F);
const _textMuted = Color(0xFF627387);

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          .collection('users')
          .get();

      final users = snapshot.docs
          .map((doc) => <String, dynamic>{...doc.data(), '_id': doc.id})
          .toList();

      // Sort: admins first, then by full name
      users.sort((a, b) {
        final aIsAdmin = (a['role'] as String?) == 'admin';
        final bIsAdmin = (b['role'] as String?) == 'admin';
        if (aIsAdmin != bIsAdmin) return aIsAdmin ? -1 : 1;
        final aName = _nameOf(a).toLowerCase();
        final bName = _nameOf(b).toLowerCase();
        return aName.compareTo(bName);
      });

      if (mounted) {
        setState(() {
          _allUsers = users;
          _filtered = users;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les utilisateurs.';
          _loading = false;
        });
      }
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filtered = _allUsers);
      return;
    }
    setState(() {
      _filtered = _allUsers.where((u) {
        final name = _nameOf(u).toLowerCase();
        final email = (_email(u)).toLowerCase();
        final phone = (_phone(u)).toLowerCase();
        return name.contains(query) ||
            email.contains(query) ||
            phone.contains(query);
      }).toList();
    });
  }

  // ── Safe field readers ────────────────────────────────────────────────────

  static String _nameOf(Map<String, dynamic> u) {
    final first = _str(u['firstName']);
    final last = _str(u['lastName']);
    final full = _str(u['fullName']);
    if (first.isNotEmpty || last.isNotEmpty) {
      return [first, last].where((s) => s.isNotEmpty).join(' ');
    }
    return full;
  }

  static String _email(Map<String, dynamic> u) => _str(u['email']);
  static String _phone(Map<String, dynamic> u) => _str(u['phone']);
  static String _insurance(Map<String, dynamic> u) =>
      _str(u['insuranceNumber']);
  static String _role(Map<String, dynamic> u) =>
      _str(u['role']).isEmpty ? 'user' : _str(u['role']);

  static String _str(dynamic v) {
    final s = v?.toString().trim();
    return s == null || s.isEmpty ? '' : s;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
          'Utilisateurs',
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
                  _HeaderCard(count: _allUsers.length),
                  const SizedBox(height: 4),
                  _SearchBar(controller: _searchController),
                  const SizedBox(height: 4),
                  Expanded(child: _UserList(users: _filtered)),
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
              color: const Color(0xFFE9F1FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.people_alt_outlined, color: _blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Utilisateurs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Comptes enregistrés sur Axiora',
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
              '$count comptes',
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

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14, color: _navy),
        decoration: InputDecoration(
          hintText: 'Rechercher par nom, email ou téléphone…',
          hintStyle: const TextStyle(fontSize: 13, color: _textMuted),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _textMuted,
            size: 20,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _blue, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── User list ─────────────────────────────────────────────────────────────────

class _UserList extends StatelessWidget {
  const _UserList({required this.users});

  final List<Map<String, dynamic>> users;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: _textMuted),
            SizedBox(height: 12),
            Text(
              'Aucun utilisateur trouvé.',
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _UserCard(data: users[index]),
    );
  }
}

// ── User card ─────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  const _UserCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final name = _AdminUsersScreenState._nameOf(data);
    final email = _AdminUsersScreenState._email(data);
    final phone = _AdminUsersScreenState._phone(data);
    final insurance = _AdminUsersScreenState._insurance(data);
    final role = _AdminUsersScreenState._role(data);
    final isAdmin = role == 'admin';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar circle
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isAdmin
                  ? const Color(0xFFE9F1FF)
                  : const Color(0xFFEAF7F0),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isAdmin ? _blue : _green,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name.isNotEmpty ? name : 'Nom inconnu',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RoleBadge(role: role, isAdmin: isAdmin),
                  ],
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  _InfoLine(icon: Icons.email_outlined, text: email),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  _InfoLine(icon: Icons.phone_outlined, text: phone),
                ],
                if (insurance.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  _InfoLine(
                    icon: Icons.verified_user_outlined,
                    text: insurance,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role, required this.isAdmin});

  final String role;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFE9F1FF) : const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isAdmin
              ? _blue.withValues(alpha: 0.24)
              : _green.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        isAdmin ? 'admin' : 'user',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: isAdmin ? _blue : _green,
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

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
