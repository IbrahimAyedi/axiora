import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/config/app_constants.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/storage/cache_keys.dart';

// splash screen mte3 app
// yban 2 seconds ba3ed ychecki session: home wala login
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // نستناو 2 seconds ba3ed ncheckiw session mte3 user
    Future<void>.delayed(const Duration(seconds: 2), _checkSession);
  }

  // tchecki ken user connecté w rememberMe true
  Future<void> _checkSession() async {
    // ken widget ma عادش mounted, nوقفou
    if (!mounted) return;

    try {
      // njibou shared preferences
      final prefs = await SharedPreferences.getInstance();

      // njibou remember me value
      final rememberMe = prefs.getBool(CacheKeys.rememberMe) ?? false;

      // njibou current firebase user
      final currentUser = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      // ken user connected w rememberMe true, nemchiw lel home
      if (currentUser != null && rememberMe) {
        context.go(RouteNames.homePath);
      } else {
        // sinon ken user connected ama rememberMe false, na3mlou sign out
        if (currentUser != null) await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        // nemchiw lel login
        context.go(RouteNames.loginPath);
      }
    } catch (_) {
      // ken fama error, nemchiw lel login par défaut
      if (!mounted) return;
      context.go(RouteNames.loginPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body mte3 splash screen
      body: Container(
        // background gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF124170), Color(0xFF0B2C4A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        // safe area bech contenu ma يدخلch fi status bar
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),

                // logo/icon container
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 28),

                // app name
                Text(
                  AppConstants.appName,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 10),

                // app tagline
                Text(
                  AppConstants.appTagline,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 32),

                // loading indicator + loading text
                const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Preparing secure mobile workspace...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
