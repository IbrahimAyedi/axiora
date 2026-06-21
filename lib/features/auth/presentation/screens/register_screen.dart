import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/storage/cache_keys.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_input.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _insuranceNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Business logic — unchanged ────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    if (mounted) setState(() => _submitting = true);

    final insuranceNumber = _insuranceNumberController.text.trim();

    try {
      final insuranceDoc = await FirebaseFirestore.instance
          .collection('insurance_users')
          .doc(insuranceNumber)
          .get();

      if (insuranceDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ce numéro d'assurance est déjà enregistré."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final uid = userCredential.user!.uid;
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
              .trim();

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

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(CacheKeys.rememberMe, true);

      if (!mounted) return;
      context.go(RouteNames.homePath);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Un compte existe déjà pour cet e-mail.';
          break;
        case 'weak-password':
          message = 'Le mot de passe est trop faible.';
          break;
        case 'invalid-email':
          message = 'Adresse e-mail invalide.';
          break;
        default:
          message = 'Inscription échouée. Veuillez réessayer.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de créer le profil. Veuillez réessayer.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background image ────────────────────────────────────────────
            Image.asset(
              'assets/images/bg_auth_axiora.jpeg',
              fit: BoxFit.cover,
            ),

            // ── Soft light overlay ──────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x80F4F7FB), // top — 50 %
                    Color(0xBBF4F7FB), // mid — 73 %
                    Color(0xDDFFFFFF), // bottom — 87 %
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // ── Scrollable content ──────────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Back row ──────────────────────────────────────────
                      _BackButton(onTap: () => context.pop()),
                      const SizedBox(height: 24),

                      // ── Logo ─────────────────────────────────────────────
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Page header (outside card) ────────────────────────
                      Text(
                        'Créer votre espace Axiora',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Quelques informations suffisent pour préparer vos constats.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Form card ─────────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 32,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Section 1: Informations personnelles ──────────
                            const _SectionHeader(
                              icon: Icons.person_outline_rounded,
                              label: 'Informations personnelles',
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: AppTextInput(
                                    label: 'Prénom',
                                    controller: _firstNameController,
                                    validator: (v) => Validators.requiredField(
                                      v,
                                      label: 'Prénom',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: AppTextInput(
                                    label: 'Nom',
                                    controller: _lastNameController,
                                    validator: (v) => Validators.requiredField(
                                      v,
                                      label: 'Nom',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            AppTextInput(
                              label: 'Téléphone',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_outlined,
                              hint: '+216 00 000 000',
                              validator: Validators.phone,
                            ),
                            const SizedBox(height: 12),

                            AppTextInput(
                              label: 'Email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                              hint: 'exemple@email.com',
                              validator: Validators.email,
                            ),

                            // ── Section 2: Assurance ──────────────────────────
                            const _SectionDivider(),

                            const _SectionHeader(
                              icon: Icons.shield_outlined,
                              label: 'Assurance',
                            ),
                            const SizedBox(height: 14),

                            AppTextInput(
                              label: "Numéro d'assurance",
                              controller: _insuranceNumberController,
                              prefixIcon: Icons.badge_outlined,
                              hint: 'INS-2026-0001',
                              validator: (v) => Validators.requiredField(
                                v,
                                label: "Numéro d'assurance",
                              ),
                            ),

                            // ── Section 3: Sécurité du compte ─────────────────
                            const _SectionDivider(),

                            const _SectionHeader(
                              icon: Icons.lock_outline_rounded,
                              label: 'Sécurité du compte',
                            ),
                            const SizedBox(height: 14),

                            AppTextInput(
                              label: 'Mot de passe',
                              controller: _passwordController,
                              obscureText: true,
                              prefixIcon: Icons.lock_outline,
                              validator: Validators.password,
                            ),
                            const SizedBox(height: 12),

                            AppTextInput(
                              label: 'Confirmer le mot de passe',
                              controller: _confirmPasswordController,
                              obscureText: true,
                              prefixIcon: Icons.lock_reset_outlined,
                              validator: (v) => Validators.confirmPassword(
                                v,
                                _passwordController.text,
                              ),
                            ),

                            const SizedBox(height: 28),

                            // ── Primary action ────────────────────────────────
                            SizedBox(
                              height: 54,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _submitting
                                        ? [
                                            const Color(0xFFB0BEC5),
                                            const Color(0xFF90A4AE),
                                          ]
                                        : [
                                            const Color(0xFF1769AA),
                                            const Color(0xFF0B2D4D),
                                          ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ElevatedButton(
                                  onPressed: _submitting ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    textStyle: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  child: Text(
                                    _submitting
                                        ? 'Création…'
                                        : 'Créer mon compte',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Inline link → login ───────────────────────────
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Déjà un compte ? ',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.pop(),
                                    child: Text(
                                      'Se connecter',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: AppColors.trustBlue,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Back button — compact icon + label
// ─────────────────────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Retour',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header — icon chip + label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 15, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Visual divider between sections
// ─────────────────────────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Divider(height: 1),
    );
  }
}
