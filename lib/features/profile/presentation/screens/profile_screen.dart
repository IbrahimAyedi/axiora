import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/providers/app_session_provider.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/app_text_input.dart';
import '../../../../core/widgets/section_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  Map<String, dynamic>? _profileData;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authUser = FirebaseAuth.instance.currentUser;
    final session = ref.read(appSessionProvider);

    if (authUser == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final fallbackParts = _splitName(
      session.currentUser.fullName ?? authUser.displayName,
    );

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .get();

      final data = snapshot.data() ?? <String, dynamic>{};
      final firstName = _stringOrNull(data['firstName']) ?? fallbackParts[0];
      final lastName = _stringOrNull(data['lastName']) ?? fallbackParts[1];
      final phone =
          _stringOrNull(data['phone']) ??
          session.currentUser.phoneNumber ??
          authUser.phoneNumber ??
          '';

      _firstNameController.text = firstName;
      _lastNameController.text = lastName;
      _phoneController.text = phone;

      if (!mounted) return;
      setState(() {
        _profileData = {
          ...data,
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
          'email':
              _stringOrNull(data['email']) ??
              authUser.email ??
              session.currentUser.email,
        };
        _loading = false;
      });
    } catch (_) {
      _firstNameController.text = fallbackParts[0];
      _lastNameController.text = fallbackParts[1];
      _phoneController.text =
          session.currentUser.phoneNumber ?? authUser.phoneNumber ?? '';

      if (!mounted) return;
      setState(() {
        _profileData = {
          'email': authUser.email ?? session.currentUser.email,
          'firstName': fallbackParts[0],
          'lastName': fallbackParts[1],
          'phone': _phoneController.text,
        };
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _saving) return;

    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;

    setState(() => _saving = true);

    try {
      final currentData = _profileData ?? const <String, dynamic>{};
      final email =
          _stringOrNull(currentData['email']) ??
          authUser.email ??
          ref.read(appSessionProvider).currentUser.email;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .set({
            'uid': authUser.uid,
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'email': email,
            'insuranceId': currentData['insuranceId'],
            'contractNumber': currentData['contractNumber'],
            'agencyCode': currentData['agencyCode'],
            'createdAt':
                currentData['createdAt'] ?? FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      ref
          .read(appSessionProvider.notifier)
          .syncCurrentUserProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phone: _phoneController.text.trim(),
          );

      if (!mounted) return;
      setState(() {
        _profileData = {
          ...currentData,
          'uid': authUser.uid,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': email,
        };
        _saving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to save profile')));
    }
  }

  String _displayValue(Object? value) {
    if (value == null) return 'Not set';
    final text = value.toString().trim();
    return text.isEmpty ? 'Not set' : text;
  }

  String? _stringOrNull(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  List<String> _splitName(String? fullName) {
    final parts =
        fullName
            ?.trim()
            .split(RegExp(r'\s+'))
            .where((value) => value.isNotEmpty)
            .toList() ??
        <String>[];

    if (parts.isEmpty) return ['', ''];
    if (parts.length == 1) return [parts.first, ''];
    return [parts.first, parts.sublist(1).join(' ')];
  }

  @override
  Widget build(BuildContext context) {
    final email = _displayValue(_profileData?['email']);
    final insuranceNumber = _displayValue(_profileData?['insuranceNumber']);
    final insuranceId = _displayValue(_profileData?['insuranceId']);
    final contractNumber = _displayValue(_profileData?['contractNumber']);
    final agencyCode = _displayValue(_profileData?['agencyCode']);

    return AppPageScaffold(
      title: 'Profile',
      subtitle: 'Your account details',
      actions: [
        IconButton(
          onPressed: () => context.push(RouteNames.settingsPath),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      body: _loading
          ? const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    title: 'Personal info',
                    subtitle: 'Editable fields synced to Firestore',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextInput(
                          label: 'First name',
                          controller: _firstNameController,
                          prefixIcon: Icons.badge_outlined,
                          validator: (value) => Validators.requiredField(
                            value,
                            label: 'First name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppTextInput(
                          label: 'Last name',
                          controller: _lastNameController,
                          prefixIcon: Icons.badge_outlined,
                          validator: (value) => Validators.requiredField(
                            value,
                            label: 'Last name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppTextInput(
                          label: 'Phone',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                          validator: Validators.phone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Account details',
                    subtitle: 'Read-only profile data from users/{uid}',
                    child: Column(
                      children: [
                        _InfoRow(label: 'Email', value: email),
                        const SizedBox(height: 12),
                        _InfoRow(
                          label: 'Insurance number',
                          value: insuranceNumber,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'Insurance ID', value: insuranceId),
                        const SizedBox(height: 12),
                        _InfoRow(
                          label: 'Contract number',
                          value: contractNumber,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'Agency code', value: agencyCode),
                        const SizedBox(height: 12),
                        _InfoRow(
                          label: 'Role',
                          value:
                              ref.watch(appSessionProvider).currentUser.role ??
                              'user',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: _saving ? 'Saving...' : 'Save changes',
                    icon: Icons.save_outlined,
                    onPressed: _saving ? null : _saveProfile,
                  ),
                ],
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
