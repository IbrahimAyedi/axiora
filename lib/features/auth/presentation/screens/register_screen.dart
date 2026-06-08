import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/storage/cache_keys.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_input.dart';

// screen mte3 register
// user y3abi personal info w ya3mel account b FirebaseAuth
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // key mte3 form bech nvalidiw inputs
  final _formKey = GlobalKey<FormState>();

  // controllers mte3 form fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    // nfas5ou controllers bech ma ysirch memory leak
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _insuranceNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // function mte3 account creation
  Future<void> _submit() async {
    // ken form ghalet, nوقفou
    if (!_formKey.currentState!.validate()) return;

    // insurance number eli user ktebou
    final insuranceNumber = _insuranceNumberController.text.trim();

    try {
      // Check if insurance number is already registered
      // nverifiw ken insurance number deja mawjoud fi insurance_users
      final insuranceDoc = await FirebaseFirestore.instance
          .collection('insurance_users')
          .doc(insuranceNumber)
          .get();

      // ken insurance number deja mawjoud, nوقفou registration
      if (insuranceDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insurance number already registered.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // creation mte3 user fi FirebaseAuth b email w password
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // uid mte3 user jdid
      final uid = userCredential.user!.uid;

      // full name men first name + last name
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
              .trim();

      // Create user document
      // nsajlou profile mte3 user fi collection users
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'fullName': fullName,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'insuranceNumber': insuranceNumber,
        'insuranceId': null,
        'contractNumber': null,
        'agencyCode': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create insurance_users lookup document
      // lookup table: insurance number -> uid
      // nesta3mlouha bech nlawejou 3la User B b insurance number
      await FirebaseFirestore.instance
          .collection('insurance_users')
          .doc(insuranceNumber)
          .set({
            'uid': uid,
            'fullName': fullName,
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      // nsavew rememberMe true localement
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(CacheKeys.rememberMe, true);

      if (!mounted) return;

      // ba3d registration success, nemchiw lel home
      context.go(RouteNames.homePath);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      // n7adrou message حسب FirebaseAuth error code
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists for this email.';
          break;
        case 'weak-password':
          message = 'The password is too weak.';
          break;
        case 'invalid-email':
          message = 'The email address is invalid.';
          break;
        default:
          message = 'Registration failed. Please try again.';
      }

      // nwarriw error fi SnackBar
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      // error general ken Firestore wala creation profile tfشل
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create user profile. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ncheckiw dark mode wala light mode
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // background color حسب theme
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF3F6FB),

      // appbar fih back button
      appBar: AppBar(
        leading: const BackButton(),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),

      // body mte3 register screen
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          child: Form(
            // form key lel validation
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                // badge mte3 new account
                const AppBadge(label: 'New account'),
                const SizedBox(height: 14),

                // title mte3 screen
                Text(
                  'Create your workspace',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // description sghira
                Text(
                  'Set up your account now and connect real authentication later.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Personal info section ────────────────────────────────
                // section mte3 personal info
                _SectionLabel(
                  icon: Icons.badge_outlined,
                  label: 'Personal info',
                ),
                const SizedBox(height: 10),

                // card fih personal info inputs
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // first name w last name fi nafs row
                        Row(
                          children: [
                            Expanded(
                              child: AppTextInput(
                                label: 'First name',
                                controller: _firstNameController,
                                prefixIcon: Icons.badge_outlined,
                                validator: (value) => Validators.requiredField(
                                  value,
                                  label: 'First name',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppTextInput(
                                label: 'Last name',
                                controller: _lastNameController,
                                validator: (value) => Validators.requiredField(
                                  value,
                                  label: 'Last name',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // phone input
                        AppTextInput(
                          label: 'Phone',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                          hint: '+216 00 000 000',
                          validator: Validators.phone,
                        ),
                        const SizedBox(height: 12),

                        // insurance number input
                        AppTextInput(
                          label: 'Insurance number',
                          controller: _insuranceNumberController,
                          prefixIcon: Icons.shield_outlined,
                          hint: 'INS-2026-0001',
                          validator: (value) => Validators.requiredField(
                            value,
                            label: 'Insurance number',
                          ),
                        ),
                        const SizedBox(height: 12),

                        // email input
                        AppTextInput(
                          label: 'Email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          hint: 'example@email.com',
                          validator: Validators.email,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Security section ─────────────────────────────────────
                // section mte3 security/password
                _SectionLabel(icon: Icons.lock_outline, label: 'Security'),
                const SizedBox(height: 10),

                // card fih password inputs
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // password input
                        AppTextInput(
                          label: 'Password',
                          controller: _passwordController,
                          obscureText: true,
                          prefixIcon: Icons.lock_outline,
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 12),

                        // confirm password input
                        AppTextInput(
                          label: 'Confirm password',
                          controller: _confirmPasswordController,
                          obscureText: true,
                          prefixIcon: Icons.lock_reset_outlined,
                          validator: (value) => Validators.confirmPassword(
                            value,
                            _passwordController.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Actions ──────────────────────────────────────────────
                // create account button
                AppButton(
                  label: 'Create account',
                  icon: Icons.person_add_alt_1,
                  onPressed: _submit,
                ),
                const SizedBox(height: 10),

                // back to sign in button
                AppButton(
                  label: 'Back to sign in',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.pop(),
                ),

                const SizedBox(height: 20),

                // footer text
                Center(
                  child: Text(
                    'Powered by Firebase Authentication.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// widget sghir ywarri section label b icon
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  // icon mte3 section
  final IconData icon;

  // label mte3 section
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // section icon
        Icon(
          icon,
          size: 15,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),

        // section label
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
