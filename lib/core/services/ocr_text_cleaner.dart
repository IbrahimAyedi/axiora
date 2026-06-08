import '../models/ocr_result.dart';

/// OCR text cleaning and normalization layer.
///
/// Applies character-substitution rules and known-value corrections to raw
/// ML Kit output BEFORE document-specific parsing.  The goal is to make the
/// parsers more reliable without touching their logic.
///
/// Rules are intentionally simple and additive — add more entries to the
/// static lists below to extend coverage without touching parsing logic.
class OcrTextCleaner {
  OcrTextCleaner._();

  // ---------------------------------------------------------------------------
  // Entry point
  // ---------------------------------------------------------------------------

  /// Returns a new [OcrTextResult] whose [rawText] and [lines] have been
  /// normalized.  The original object is never modified.
  static OcrTextResult clean(OcrTextResult raw) {
    final cleaned = _cleanText(raw.rawText);
    final cleanedLines = raw.lines
        .map(_cleanText)
        .where((line) => line.isNotEmpty)
        .toList();
    return OcrTextResult(
      rawText: cleaned,
      lines: cleanedLines,
      processedAt: raw.processedAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Core pipeline
  // ---------------------------------------------------------------------------

  static String _cleanText(String text) {
    var result = text;
    result = _normalizeWhitespace(result);
    result = _fixOcrCharacterErrors(result);
    result = _fixKnownBrandNames(result);
    result = _fixKnownInsuranceCompanies(result);
    result = _normalizeWhitespace(result); // second pass after substitutions
    return result;
  }

  // ---------------------------------------------------------------------------
  // Step 1 – Whitespace normalisation
  // ---------------------------------------------------------------------------

  static String _normalizeWhitespace(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        // Collapse multiple spaces to one (preserve newlines)
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        // Remove trailing spaces on each line
        .replaceAll(RegExp(r' +\n'), '\n')
        .replaceAll(RegExp(r'\n +'), '\n')
        // Collapse 3+ blank lines to 2
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  // ---------------------------------------------------------------------------
  // Step 2 – Common OCR character confusions
  // ---------------------------------------------------------------------------

  /// Character-level substitutions that apply globally.
  /// Each entry: (wrong pattern, correct replacement).
  ///
  /// Caution: these are ORDER-SENSITIVE — more specific rules first.
  static final List<(RegExp, String)> _charSubstitutions = [
    // "0" misread as "O" or vice-versa in clearly numeric contexts
    // (handled in brand/VIN-specific rules below, not globally to avoid
    //  breaking legitimate text like "CONTRAT N°" → avoid blanket replace)

    // Stray backtick or pipe inside alphanumeric words
    (RegExp(r'(?<=[A-Za-z0-9])[`|](?=[A-Za-z0-9])'), ''),

    // Two or more consecutive dashes that OCR splits from hyphens
    (RegExp(r'--+'), '-'),

    // Dot used as letter separator in words (e.g. 'M.E.R.C.E.D.E.S')
    (RegExp(r'(?<=[A-Z])\.(?=[A-Z])'), ''),
  ];

  static String _fixOcrCharacterErrors(String text) {
    var result = text;
    for (final (pattern, replacement) in _charSubstitutions) {
      result = result.replaceAll(pattern, replacement);
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Step 3 – Known vehicle brand corrections
  // ---------------------------------------------------------------------------

  /// Maps a regex pattern (case-insensitive, word-boundary anchored where
  /// possible) to the canonical brand name.
  static final List<(RegExp, String)> _brandCorrections = [
    // Peugeot — "0" mistaken for "O", trailing noise
    (RegExp(r'\bPEUGE[0O]T\b', caseSensitive: false), 'PEUGEOT'),
    (RegExp(r'\bPEUG[EE]OT\b', caseSensitive: false), 'PEUGEOT'),
    (RegExp(r'\bPEUGT\b', caseSensitive: false), 'PEUGEOT'),

    // Renault — "U" misread as "II", "L" as "1", etc.
    (RegExp(r'\bRENAU[1IL]T\b', caseSensitive: false), 'RENAULT'),
    (RegExp(r'\bRENAUIT\b', caseSensitive: false), 'RENAULT'),
    (RegExp(r'\bRENAU[L1]\b', caseSensitive: false), 'RENAULT'),

    // Citroën — various OCR confusions
    (RegExp(r'\bC[1I]TROEN\b', caseSensitive: false), 'CITROEN'),
    (RegExp(r'\bC[1I]TR[O0]EN\b', caseSensitive: false), 'CITROEN'),
    (RegExp(r'\bCITROËN\b', caseSensitive: false), 'CITROEN'),

    // Mercedes-Benz — "2" for "Z", "5" for "S", missing hyphen
    (RegExp(r'\bMERCEDES[\s\-]*BEN[Z2S]\b', caseSensitive: false), 'MERCEDES-BENZ'),
    (RegExp(r'\bMERCEDES[\s\-]*BENS\b', caseSensitive: false), 'MERCEDES-BENZ'),
    (RegExp(r'\bMERCEDES[\s\-]*BEN2\b', caseSensitive: false), 'MERCEDES-BENZ'),
    (RegExp(r'\bMERCEDES\b', caseSensitive: false), 'MERCEDES-BENZ'),

    // Opel — leading "0" misread
    (RegExp(r'\b0PEL\b', caseSensitive: false), 'OPEL'),
    (RegExp(r'\b[O0]PEL\b', caseSensitive: false), 'OPEL'),

    // Volkswagen abbreviations / noise
    (RegExp(r'\bV[O0]LKSWAGEN\b', caseSensitive: false), 'VOLKSWAGEN'),
    (RegExp(r'\bVOLKSWAGEN\b', caseSensitive: false), 'VOLKSWAGEN'),
    (RegExp(r'\bVW\b', caseSensitive: false), 'VOLKSWAGEN'),

    // Toyota
    (RegExp(r'\bT[O0]Y[O0]TA\b', caseSensitive: false), 'TOYOTA'),

    // Hyundai
    (RegExp(r'\bHYUNDA[1I]\b', caseSensitive: false), 'HYUNDAI'),
    (RegExp(r'\bHYNDAI\b', caseSensitive: false), 'HYUNDAI'),

    // Nissan
    (RegExp(r'\bN[1I]SSAN\b', caseSensitive: false), 'NISSAN'),
    (RegExp(r'\bNISSAN\b', caseSensitive: false), 'NISSAN'),

    // Fiat
    (RegExp(r'\bF[1I]AT\b', caseSensitive: false), 'FIAT'),

    // Kia
    (RegExp(r'\bK[1I]A\b', caseSensitive: false), 'KIA'),

    // Dacia
    (RegExp(r'\bDAC[1I]A\b', caseSensitive: false), 'DACIA'),

    // Honda
    (RegExp(r'\bH[O0]NDA\b', caseSensitive: false), 'HONDA'),

    // BMW — rarely mangled but just in case
    (RegExp(r'\bBMW\b', caseSensitive: false), 'BMW'),

    // Audi
    (RegExp(r'\bAUD[1I]\b', caseSensitive: false), 'AUDI'),

    // Seat
    (RegExp(r'\bSEAT\b', caseSensitive: false), 'SEAT'),

    // Skoda
    (RegExp(r'\bSKODA\b', caseSensitive: false), 'SKODA'),

    // Ford
    (RegExp(r'\bF[O0]RD\b', caseSensitive: false), 'FORD'),

    // Mazda
    (RegExp(r'\bMAZDA\b', caseSensitive: false), 'MAZDA'),

    // Mitsubishi
    (RegExp(r'\bM[1I]TSUB[1I]SH[1I]\b', caseSensitive: false), 'MITSUBISHI'),

    // Suzuki
    (RegExp(r'\bSUZUK[1I]\b', caseSensitive: false), 'SUZUKI'),

    // Chevrolet
    (RegExp(r'\bCHEVR[O0]LET\b', caseSensitive: false), 'CHEVROLET'),

    // Volvo
    (RegExp(r'\bV[O0]LV[O0]\b', caseSensitive: false), 'VOLVO'),

    // Iveco
    (RegExp(r'\b[1I]VEC[O0]\b', caseSensitive: false), 'IVECO'),
  ];

  static String _fixKnownBrandNames(String text) {
    var result = text;
    for (final (pattern, replacement) in _brandCorrections) {
      result = result.replaceAllMapped(pattern, (m) {
        // Preserve original casing style: if source was all-caps keep all-caps,
        // otherwise use canonical form.
        final src = m.group(0) ?? '';
        return src == src.toUpperCase() ? replacement.toUpperCase() : replacement;
      });
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Step 4 – Known Tunisian insurance company name corrections
  // ---------------------------------------------------------------------------

  static final List<(RegExp, String)> _insuranceCorrections = [
    (RegExp(r'\bBNA\s+ASSURANCES?\b', caseSensitive: false), 'BNA ASSURANCES'),
    (RegExp(r'\bAMI\s+ASSURANCES?\b', caseSensitive: false), 'AMI ASSURANCES'),
    (RegExp(r'\bZ[1I]T[O0]UNA\s+TAKAF[U]L\b', caseSensitive: false), 'ZITOUNA TAKAFUL'),
    (RegExp(r'\bATT[1I]JAR[1I]\s+ASSURANCE\b', caseSensitive: false), 'ATTIJARI ASSURANCE'),
    (RegExp(r'\bMAGHREB[1I]A\b', caseSensitive: false), 'MAGHREBIA'),
    (RegExp(r'\bC[O0]TUNACE\b', caseSensitive: false), 'COTUNACE'),
    (RegExp(r'\bASTREE\b', caseSensitive: false), 'ASTREE'),
    (RegExp(r'\bC[O0]MAR\b', caseSensitive: false), 'COMAR'),
    (RegExp(r'\bLL[O0]YD\b', caseSensitive: false), 'LLOYD'),
    (RegExp(r'\bSTAR\b', caseSensitive: false), 'STAR'),
    (RegExp(r'\bGAT\b', caseSensitive: false), 'GAT'),
  ];

  static String _fixKnownInsuranceCompanies(String text) {
    var result = text;
    for (final (pattern, replacement) in _insuranceCorrections) {
      result = result.replaceAllMapped(pattern, (m) {
        final src = m.group(0) ?? '';
        return src == src.toUpperCase() ? replacement.toUpperCase() : replacement;
      });
    }
    return result;
  }
}
