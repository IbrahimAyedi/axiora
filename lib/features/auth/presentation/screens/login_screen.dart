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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _rememberMe = prefs.getBool(CacheKeys.rememberMe) ?? false);
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _identifierController.text.trim(),
        password: _passwordController.text,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(CacheKeys.rememberMe, _rememberMe);

      if (!mounted) return;
      context.go(RouteNames.homePath);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);

      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Aucun compte trouvé pour cet e-mail.';
          break;
        case 'wrong-password':
          message = 'Mot de passe incorrect.';
          break;
        case 'invalid-email':
          message = 'Adresse e-mail invalide.';
          break;
        case 'invalid-credential':
          message = 'E-mail ou mot de passe incorrect.';
          break;
        default:
          message = 'Connexion échouée. Veuillez réessayer.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

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
            // ── Background image ──────────────────────────────────────────
            Image.asset(
              'assets/images/bg_auth_axiora.jpeg',
              fit: BoxFit.cover,
            ),

            // ── Very soft white/light-blue overlay ────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x55F4F7FB), // top — 33 %
                    Color(0x99F4F7FB), // mid — 60 %
                    Color(0xCCFFFFFF), // bottom — 80 %
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),

            // ── Scrollable content ────────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 44),

                      // ── Logo + brand ──────────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
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
                            const SizedBox(height: 12),
                            Text(
                              'Axiora',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Auth card ─────────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0B2D4D,
                              ).withValues(alpha: 0.07),
                              blurRadius: 28,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title
                            Text(
                              'Bienvenue',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Subtitle
                            Text(
                              'Connectez-vous à votre espace Axiora.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Email
                            AppTextInput(
                              label: 'Email',
                              hint: 'exemple@email.com',
                              controller: _identifierController,
                              prefixIcon: Icons.person_outline,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) => Validators.requiredField(
                                value,
                                label: 'Email',
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Password
                            AppTextInput(
                              label: 'Mot de passe',
                              hint: 'Votre mot de passe',
                              controller: _passwordController,
                              obscureText: true,
                              prefixIcon: Icons.lock_outline,
                              validator: Validators.password,
                            ),
                            const SizedBox(height: 6),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {},
                                child: Text(
                                  'Mot de passe oublié ?',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.trustBlue,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Remember me
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) =>
                                      setState(() => _rememberMe = v ?? false),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  activeColor: AppColors.primary,
                                ),
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _rememberMe = !_rememberMe,
                                  ),
                                  child: Text(
                                    'Rester connecté',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Se connecter — gradient button, no icon
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
                                    _submitting ? 'Connexion…' : 'Se connecter',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Inline link → register
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    "Vous n'avez pas de compte ? ",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.push(
                                      RouteNames.registerPath,
                                    ),
                                    child: Text(
                                      'Créer un compte',
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
