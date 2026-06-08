import 'package:flutter/services.dart';
// exception custom ki valeur importante mawjoudach fil env

class EnvConfigException implements Exception {
  const EnvConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

// classe feha config mte3 environment
//nest bech na9row values mel .env
abstract final class EnvConfig {
  static Future<Map<String, String>>? _cachedValues;
  // tjib URL mte3 damage prediction API
  static Future<String> damagePredictUrl() async {
    const dartDefineValue = String.fromEnvironment('DAMAGE_PREDICT_URL');
    // ken dart-define fih valeur, nraj3ouha

    if (dartDefineValue.trim().isNotEmpty) return dartDefineValue.trim();
    // ken ma famech dart-define, nقرaw mel .env
    final values = await _loadValues();
    // nakhdhou DAMAGE_PREDICT_URL mel .env
    final value = values['DAMAGE_PREDICT_URL']?.trim();
    // ken URL mawjoudach, narmi exception

    if (value == null || value.isEmpty) {
      throw const EnvConfigException('Missing DAMAGE_PREDICT_URL in .env.');
    }

    return value;
  }

  // tjib confidence threshold mte3 damage prediction
  static Future<double> damagePredictionConfidence() async {
    const defaultConfidence = 0.25;
    // na9row values mel .env
    final values = await _loadValues();
    final rawValue = values['DAMAGE_PREDICT_CONF']?.trim();
    if (rawValue == null || rawValue.isEmpty) return defaultConfidence;

    final parsed = double.tryParse(rawValue);
    if (parsed == null || parsed <= 0 || parsed > 1) {
      return defaultConfidence;
    }
    // nerj3ou confidence eli jeya mel .env
    return parsed;
  }
// load values mel .env w cache-ihom bech ma n9rawch kol marra
  static Future<Map<String, String>> _loadValues() {
    return _cachedValues ??= _readEnvFile();
  }

  static Future<Map<String, String>> _readEnvFile() async {
    try {
      final contents = await rootBundle.loadString('.env');
      return _parse(contents);
    } catch (_) {
      return const <String, String>{};
    }
  }
  // t7awel contenu .env l Map<String, String>
  static Map<String, String> _parse(String contents) {
        // houni n7otou kol key/value mel .env

    final values = <String, String>{};
        // n9asmou file 3la lignes

    final lines = contents.split(RegExp(r'\r?\n'));

    for (final rawLine in lines) {
      final line = rawLine.trim();
            // nskipiw lignes ferghin w comments

      if (line.isEmpty || line.startsWith('#')) continue;
      // nlawej 3la separator =

      final separatorIndex = line.indexOf('=');
            // ken ma famech key=value valide, nskipiw ligne

      if (separatorIndex <= 0) continue;

      final key = line.substring(0, separatorIndex).trim();
      var value = line.substring(separatorIndex + 1).trim();

      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }

      if (key.isNotEmpty) values[key] = value;
    }

    return values;
  }
}
