import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// classe feha configuration mte3 localization
// nesta3mlouha bech app ta3ref les langues supportees
abstract final class AppL10n {
  static const supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
  ];
  // delegates mte3 Flutter localization
  // ykhalou widgets mte3 Material, Cupertino w Flutter yetarjmou 7asb locale
  static const localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}
