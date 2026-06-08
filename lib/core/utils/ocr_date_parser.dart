/// Safe date-parsing utility for raw OCR text.
///
/// Supports the most common formats found in Tunisian documents:
///   DD/MM/YYYY   DD-MM-YYYY   DD.MM.YYYY
///   YYYY/MM/DD   YYYY-MM-DD
///
/// Rules:
/// * Never throws.
/// * Returns null when parsing fails — the caller keeps the raw string.
/// * Only returns a [DateTime] when day, month and year are all plausible.
class OcrDateParser {
  OcrDateParser._();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Try to parse [text] as a date.  Returns null on failure.
  static DateTime? tryParse(String? text) {
    if (text == null || text.trim().isEmpty) return null;

    final cleaned = text.trim();

    // Try each supported pattern in order of specificity.
    return _tryDdMmYyyy(cleaned) ??
        _tryYyyyMmDd(cleaned) ??
        _tryLooseDate(cleaned);
  }

  /// Normalise a raw date string to DD/MM/YYYY display format.
  ///
  /// Returns the original [text] unchanged when parsing fails so the UI
  /// always has something to display.
  static String normalise(String? text) {
    final dt = tryParse(text);
    if (dt == null) return text ?? '';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static final RegExp _ddMmYyyy = RegExp(
    r'^\s*(\d{1,2})\s*[/\-\.]\s*(\d{1,2})\s*[/\-\.]\s*(\d{4})\s*$',
  );

  static final RegExp _yyyyMmDd = RegExp(
    r'^\s*(\d{4})\s*[/\-\.]\s*(\d{1,2})\s*[/\-\.]\s*(\d{1,2})\s*$',
  );

  // Loose: find any date-like token anywhere in the string.
  static final RegExp _looseAny = RegExp(
    r'\b(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{4})\b'
    r'|'
    r'\b(\d{4})[/\-\.](\d{1,2})[/\-\.](\d{1,2})\b',
  );

  static DateTime? _tryDdMmYyyy(String text) {
    final m = _ddMmYyyy.firstMatch(text);
    if (m == null) return null;
    final day = int.tryParse(m.group(1)!);
    final month = int.tryParse(m.group(2)!);
    final year = int.tryParse(m.group(3)!);
    return _build(day, month, year);
  }

  static DateTime? _tryYyyyMmDd(String text) {
    final m = _yyyyMmDd.firstMatch(text);
    if (m == null) return null;
    final year = int.tryParse(m.group(1)!);
    final month = int.tryParse(m.group(2)!);
    final day = int.tryParse(m.group(3)!);
    return _build(day, month, year);
  }

  static DateTime? _tryLooseDate(String text) {
    for (final m in _looseAny.allMatches(text)) {
      // DD/MM/YYYY branch (groups 1-3 populated)
      if (m.group(1) != null) {
        final dt = _build(
          int.tryParse(m.group(1)!),
          int.tryParse(m.group(2)!),
          int.tryParse(m.group(3)!),
        );
        if (dt != null) return dt;
      }
      // YYYY/MM/DD branch (groups 4-6 populated)
      if (m.group(4) != null) {
        final dt = _build(
          int.tryParse(m.group(6)!),
          int.tryParse(m.group(5)!),
          int.tryParse(m.group(4)!),
        );
        if (dt != null) return dt;
      }
    }
    return null;
  }

  static DateTime? _build(int? day, int? month, int? year) {
    if (day == null || month == null || year == null) return null;
    if (year < 1900 || year > DateTime.now().year + 10) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    try {
      final dt = DateTime(year, month, day);
      // DateTime normalises invalid dates (e.g. Feb 30 → Mar 2).
      // Reject if normalisation shifted the day or month.
      if (dt.day != day || dt.month != month || dt.year != year) return null;
      return dt;
    } catch (_) {
      return null;
    }
  }
}
