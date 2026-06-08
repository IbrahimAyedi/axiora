import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// provider ykhazen theme mode mte3 application
// nesta3mlouh bech app ta3ref light wala dark
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
// controller ysayyer state mte3 theme mode
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void setThemeMode(ThemeMode mode) {
    if (state == mode) return;
    state = mode;
  }
}
