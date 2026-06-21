import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/storage/cache_keys.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), _checkSession);
  }

  Future<void> _checkSession() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(CacheKeys.rememberMe) ?? false;
      final currentUser = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      if (currentUser != null && rememberMe) {
        context.go(RouteNames.homePath);
        return;
      }

      if (currentUser != null) await FirebaseAuth.instance.signOut();
    } catch (_) {}

    if (!mounted) return;
    setState(() => _showButtons = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF071D33),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background image ────────────────────────────────────────────
            Image.asset(
              'assets/images/bg_auth_dark.jpg',
              fit: BoxFit.cover,
            ),

            // ── Dark navy overlay ──────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xCC071D33), // top — 80 % navy
                    Color(0xE6071D33), // mid — 90 % navy
                    Color(0xF5071D33), // bottom — 96 % navy
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // ── Content ─────────────────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 2),

                    // ── Logo ─────────────────────────────────────────────────
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF38BDF8),
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 26),

                    // ── Title ────────────────────────────────────────────────
                    const Text(
                      'Axiora',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.0,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Subtitle ─────────────────────────────────────────────
                    Text(
                      'Votre constat intelligent,\nrapide et sécurisé.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.80),
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Feature chips ─────────────────────────────────────────
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FeatureChip(label: 'OCR documents'),
                        _FeatureChip(label: 'Analyse IA'),
                        _FeatureChip(label: 'Validation rapide'),
                      ],
                    ),

                    const Spacer(flex: 3),

                    // ── CTA buttons or loader ─────────────────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      child: _showButtons
                          ? _CtaButtons(key: const ValueKey('buttons'))
                          : const _LoadingIndicator(key: ValueKey('loader')),
                    ),
                  ],
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
// Feature chip
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF38BDF8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA buttons (shown after session check)
// ─────────────────────────────────────────────────────────────────────────────

class _CtaButtons extends StatelessWidget {
  const _CtaButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary — Se connecter
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () => context.go(RouteNames.loginPath),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0B2D4D),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            child: const Text('Se connecter'),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary — Créer un compte
        SizedBox(
          height: 56,
          child: OutlinedButton(
            onPressed: () => context.push(RouteNames.registerPath),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.40),
                width: 1.4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            child: const Text('Créer un compte'),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading indicator (shown while session is being checked)
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          color: Color(0xFF38BDF8),
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
