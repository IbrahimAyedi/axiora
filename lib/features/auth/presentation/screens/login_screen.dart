import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/config/app_constants.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/storage/cache_keys.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_input.dart';

// screen mte3 login
// user yekteb email w password bech ya3mel sign in b FirebaseAuth
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // key mte3 form bech nvalidiw inputs
  final _formKey = GlobalKey<FormState>();

  // controller mte3 email input
  final _identifierController = TextEditingController();

  // controller mte3 password input
  final _passwordController = TextEditingController();

  // remember me / stay connected value
  bool _rememberMe = false;

  // true waqt login request yekhdem
  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    // nloadiw remember me saved mel local storage
    _loadRememberMe();
  }

  // tloadi remember me value men SharedPreferences
  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _rememberMe = prefs.getBool(CacheKeys.rememberMe) ?? false);
  }

  @override
  void dispose() {
    // nfas5ou controllers bech ma ysirch memory leak
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // function mte3 login
  Future<void> _submit() async {
    // ken form ghalet wala request deja yekhdem, nوقفou
    if (!_formKey.currentState!.validate() || _submitting) return;

    // nbadlou state l submitting
    setState(() => _submitting = true);

    try {
      // Firebase login b email w password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _identifierController.text.trim(),
        password: _passwordController.text,
      );

      // nsajlou remember me choice localement
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(CacheKeys.rememberMe, _rememberMe);

      if (!mounted) return;

      // ken login success, nemchiw lel home
      context.go(RouteNames.homePath);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      // nرجعou button normal
      setState(() => _submitting = false);

      // n7adrou message حسب error code mte3 Firebase
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for this email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-email':
          message = 'The email address is invalid.';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
        default:
          message = 'Authentication failed. Please try again.';
      }

      // nwarriw error fi SnackBar
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ncheckiw dark mode wala light mode
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        // background: dark simple, light gradient
        decoration: isDark
            ? BoxDecoration(color: theme.scaffoldBackgroundColor)
            : const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEBF2FA), Color(0xFFF8FAFD), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              // form key lel validation
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),

                  // ── Brand hero ──────────────────────────────────────────
                  // partie mte3 logo w app name
                  Center(
                    child: Column(
                      children: [
                        // icon container mte3 application
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.primary
                                : const Color(0xFF124170),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isDark
                                            ? theme.colorScheme.primary
                                            : const Color(0xFF124170))
                                        .withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_car_outlined,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // app name
                        Text(
                          AppConstants.appName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: isDark
                                ? theme.colorScheme.onSurface
                                : const Color(0xFF124170),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // badge sghir mte3 prototype
                        const AppBadge(label: 'Mobile-only prototype'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Headline ─────────────────────────────────────────────
                  // welcome title
                  Text(
                    'Welcome back',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // description ta7t title
                  Text(
                    'Sign in to continue your scans, reports, and saved inspection drafts.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Form card ────────────────────────────────────────────
                  // card feha email, password, remember me w buttons
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // email input
                          AppTextInput(
                            label: 'Email',
                            hint: 'example@email.com',
                            controller: _identifierController,
                            prefixIcon: Icons.person_outline,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                Validators.requiredField(value, label: 'Email'),
                          ),
                          const SizedBox(height: 14),

                          // password input
                          AppTextInput(
                            label: 'Password',
                            hint: 'Enter your password',
                            controller: _passwordController,
                            obscureText: true,
                            prefixIcon: Icons.lock_outline,
                            validator: Validators.password,
                          ),
                          const SizedBox(height: 6),

                          // forgot password button placeholder
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {},
                              child: Text(
                                'Forgot password?',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // stay connected checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v ?? false),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _rememberMe = !_rememberMe),
                                child: Text(
                                  'Stay connected',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // sign in button
                          AppButton(
                            label: _submitting ? 'Signing in...' : 'Sign in',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: _submitting ? null : _submit,
                          ),
                          const SizedBox(height: 10),

                          // divider "or"
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'or',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // button yemchi lel register screen
                          AppButton(
                            label: 'Create an account',
                            variant: AppButtonVariant.secondary,
                            onPressed: () =>
                                context.push(RouteNames.registerPath),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Disclaimer ───────────────────────────────────────────
                  // text sghir yوضح auth provider
                  Center(
                    child: Text(
                      'Powered by Firebase Authentication.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
