import 'dart:async';
//firebaseauth bech na3raf user connecte wla
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/presentation/screens/about_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/carte_grise/presentation/screens/carte_grise_autofill_screen.dart';
import '../../features/carte_grise/presentation/screens/carte_grise_result_screen.dart';
import '../../features/carte_grise/presentation/screens/scan_carte_grise_screen.dart';
import '../../features/constat/presentation/screens/accident_info_screen.dart';
import '../../features/constat/presentation/screens/constat_intro_screen.dart';
import '../../features/constat/presentation/screens/constat_review_screen.dart';
import '../../features/constat/presentation/screens/constat_signature_screen.dart';
import '../../features/constat/presentation/screens/constat_success_screen.dart';
import '../../features/constat/presentation/screens/driver_info_screen.dart';
import '../../features/constat/presentation/screens/insurance_info_screen.dart';
import '../../features/constat/presentation/screens/photos_damage_screen.dart';
import '../../features/constat/presentation/screens/vehicle_info_screen.dart';
import '../../features/admin/presentation/screens/admin_constat_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_approved_reports_screen.dart';
import '../../features/history/presentation/screens/constat_detail_screen.dart';
import '../../features/history/presentation/screens/party_b_info_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/assurance/presentation/screens/assurance_result_screen.dart';
import '../../features/assurance/presentation/screens/scan_assurance_screen.dart';
import '../../features/permis/presentation/screens/permis_result_screen.dart';
import '../../features/permis/presentation/screens/scan_permis_screen.dart';
import '../../features/scan/presentation/screens/ocr_test_screen.dart';
import '../../features/scan/presentation/screens/preview_screen.dart';
import '../../features/scan/presentation/screens/processing_screen.dart';
import '../../features/scan/presentation/screens/result_screen.dart';
import '../../features/scan/presentation/screens/scan_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // firebaseauth bech na3rfou user connecte wala le
  final auth = FirebaseAuth.instance;

  return GoRouter(
    initialLocation: RouteNames.splashPath,
    refreshListenable: _GoRouterRefreshStream(auth.authStateChanges()),
    redirect: (context, state) {
      // true ken route hiya login wala register

      final isLoggedIn = auth.currentUser != null;
      final isAuthRoute =
          state.matchedLocation == RouteNames.loginPath ||
          state.matchedLocation == RouteNames.registerPath;
      // true ken route hiya splash

      final isSplashRoute = state.matchedLocation == RouteNames.splashPath;
      // ken user mahouch connecte w yheb yodkhol lel app nraj3ouh lel login

      if (!isLoggedIn && !isAuthRoute && !isSplashRoute) {
        return RouteNames.loginPath;
      }
      // ken user connecte w yheb yarja3 lel login/register nhezouh lel home

      if (isLoggedIn && isAuthRoute) {
        return RouteNames.homePath;
      }
      // null ya3ni ma famech redirect

      return null;
    },

    // liste mte3 kol routes mte3 application
    routes: [
      GoRoute(
        path: RouteNames.splashPath,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.loginPath,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.registerPath,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // route mte3 home ba3d login
      GoRoute(
        path: RouteNames.homePath,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.profilePath,
        name: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.scanPath,
        name: RouteNames.scan,
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: RouteNames.ocrTestPath,
        name: RouteNames.ocrTest,
        builder: (context, state) => const OcrTestScreen(),
      ),
      GoRoute(
        path: RouteNames.scanCarteGrisePath,
        name: RouteNames.scanCarteGrise,
        builder: (context, state) => const ScanCarteGriseScreen(),
      ),
      GoRoute(
        path: RouteNames.carteGriseResultPath,
        name: RouteNames.carteGriseResult,
        builder: (context, state) => const CarteGriseResultScreen(),
      ),
      GoRoute(
        path: RouteNames.carteGriseAutofillPath,
        name: RouteNames.carteGriseAutofill,
        builder: (context, state) => const CarteGriseAutofillScreen(),
      ),
      GoRoute(
        path: RouteNames.scanPermisPath,
        name: RouteNames.scanPermis,
        builder: (context, state) => const ScanPermisScreen(),
      ),
      GoRoute(
        path: RouteNames.permisResultPath,
        name: RouteNames.permisResult,
        builder: (context, state) => const PermisResultScreen(),
      ),
      GoRoute(
        path: RouteNames.scanAssurancePath,
        name: RouteNames.scanAssurance,
        builder: (context, state) => const ScanAssuranceScreen(),
      ),
      GoRoute(
        path: RouteNames.assuranceResultPath,
        name: RouteNames.assuranceResult,
        builder: (context, state) => const AssuranceResultScreen(),
      ),
      GoRoute(
        path: RouteNames.previewPath,
        name: RouteNames.preview,
        builder: (context, state) => const PreviewScreen(),
      ),
      GoRoute(
        path: RouteNames.processingPath,
        name: RouteNames.processing,
        builder: (context, state) => const ProcessingScreen(),
      ),
      GoRoute(
        path: RouteNames.resultPath,
        name: RouteNames.result,
        builder: (context, state) => const ResultScreen(),
      ),
      GoRoute(
        path: RouteNames.historyPath,
        name: RouteNames.history,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: RouteNames.notificationsPath,
        name: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.settingsPath,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.aboutPath,
        name: RouteNames.about,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: RouteNames.constatIntroPath,
        name: RouteNames.constatIntro,
        builder: (context, state) => const ConstatIntroScreen(),
      ),
      GoRoute(
        path: RouteNames.accidentInfoPath,
        name: RouteNames.accidentInfo,
        builder: (context, state) => const AccidentInfoScreen(),
      ),
      GoRoute(
        path: RouteNames.driverInfoPath,
        name: RouteNames.driverInfo,
        builder: (context, state) => const DriverInfoScreen(),
      ),
      GoRoute(
        path: RouteNames.vehicleInfoPath,
        name: RouteNames.vehicleInfo,
        builder: (context, state) => const VehicleInfoScreen(),
      ),
      GoRoute(
        path: RouteNames.insuranceInfoPath,
        name: RouteNames.insuranceInfo,
        builder: (context, state) => const InsuranceInfoScreen(),
      ),
      GoRoute(
        path: RouteNames.photosDamagePath,
        name: RouteNames.photosDamage,
        builder: (context, state) => const PhotosDamageScreen(),
      ),
      GoRoute(
        path: RouteNames.constatReviewPath,
        name: RouteNames.constatReview,
        builder: (context, state) => const ConstatReviewScreen(),
      ),
      GoRoute(
        path: RouteNames.constatSignaturePath,
        name: RouteNames.constatSignature,
        builder: (context, state) => const ConstatSignatureScreen(),
      ),
      GoRoute(
        path: RouteNames.constatSuccessPath,
        name: RouteNames.constatSuccess,
        builder: (context, state) => const ConstatSuccessScreen(),
      ),
      GoRoute(
        // route detail constat, id howa constatId
        path: '/history/constat/:id',
        name: RouteNames.constatDetail,
        builder: (context, state) {
          // njibou constatId mel url
          final id = state.pathParameters['id'] ?? '';
          // njibou ownerUid ken mawjoud fil query
          final ownerUid = state.uri.queryParameters['ownerUid'];
          // n7ellou detail constat bel id w ownerUid
          return ConstatDetailScreen(constatId: id, ownerUid: ownerUid);
        },
        routes: [
          GoRoute(
            path: 'party-b-info',
            name: 'party-b-info',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final ownerUid = state.uri.queryParameters['ownerUid'];
              return PartyBInfoScreen(constatId: id, ownerUid: ownerUid);
            },
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.adminDashboardPath,
        name: RouteNames.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'constat/:id',
            name: RouteNames.adminConstatDetail,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return AdminConstatDetailScreen(constatId: id);
            },
          ),
          GoRoute(
            path: 'users',
            name: RouteNames.adminUsers,
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: 'approved-reports',
            name: RouteNames.adminApprovedReports,
            builder: (context, state) => const AdminApprovedReportsScreen(),
          ),
        ],
      ),
    ],
  );
});

// classe t7awel firebase auth stream l changenotifier
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  // subscription mte3 firebase auth stream
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
