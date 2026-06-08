import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/theme_provider.dart';
import 'config/app_constants.dart';
import 'localization/l10n.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

// Root widget mte3 l'application.
// Houni nconfiguriw router, theme, title w localization.
class App extends ConsumerWidget {
  const App({super.key});
  // Light theme mte3 l'app
  static final ThemeData _lightTheme = AppTheme.lightTheme;
  // Dark theme mte3 l'app
  static final ThemeData _darkTheme = AppTheme.darkTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Njibou router mte3 l'app mel provider
    final router = ref.read(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      // Nna7iw debug banner meli fou9
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeMode,
      // Les langues supportées
      supportedLocales: AppL10n.supportedLocales,
      // Delegates mte3 traduction/localization
      localizationsDelegates: AppL10n.localizationsDelegates,
    );
  }
}










//Provider howa blassa fi code t7ot fiha state wala data, w ay screen tnajem ta9ra menha; ki data tetbadel, l’interface tetbadel m3aha.
