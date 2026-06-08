import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// key nesta3mlouh bech nsajlou theme mode fi SharedPreferences
const String _themeModeKey = 'theme_mode';

// provider mte3 theme mode
// ykhalina na3rfou app fi light wala dark
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

// notifier ysayyer theme mode w ysajlou localement
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  // default theme howa light
  // ba3ed nloadiw theme saved mel SharedPreferences
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadThemeMode();
  }

  // tloadi theme mode saved mel local storage
  Future<void> _loadThemeMode() async {
    try {
      // njibou SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // n9raw theme mode saved
      final themeModeString = prefs.getString(_themeModeKey);

      // ken fama theme saved, nbadlou state bih
      if (themeModeString != null) {
        state = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.light,
        );
      }
    } catch (e) {
      // ken fama error, app tab9a light mode
      debugPrint('Error loading theme mode: $e');
    }
  }

  // tbadel theme mode w tsajlou fi SharedPreferences
  Future<void> setThemeMode(ThemeMode mode) async {
    // nupdatew state bech UI tetbadel
    state = mode;

    try {
      // njibou SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // nsajlou theme mode localement
      await prefs.setString(_themeModeKey, mode.toString());
    } catch (e) {
      // ken fama error fi save, nprintiw debug
      debugPrint('Error saving theme mode: $e');
    }
  }

  // toggle bin light w dark
  Future<void> toggleTheme() async {
    // ken light nwaliw dark, ken dark nwaliw light
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

    // napplyiw theme jdid w nsajlouh
    await setThemeMode(newMode);
  }
}
