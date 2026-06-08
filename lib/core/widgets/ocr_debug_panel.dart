import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A collapsible debug panel shown only in kDebugMode.
///
/// Displays raw OCR text, cleaned OCR text, all extracted fields, and the
/// confidence score from [extractedData].  Invisible in release builds.
///
/// Keys starting with '_debug_' are OCR text blocks; all other keys are
/// treated as extracted document fields.
class OcrDebugPanel extends StatefulWidget {
  const OcrDebugPanel({super.key, required this.extractedData});

  final Map<String, dynamic>? extractedData;

  @override
  State<OcrDebugPanel> createState() => _OcrDebugPanelState();
}

class _OcrDebugPanelState extends State<OcrDebugPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    if (widget.extractedData == null || widget.extractedData!.isEmpty) {
      return const SizedBox.shrink();
    }

    final data = widget.extractedData!;
    final rawOcr = data['_debug_raw_ocr'] as String?;
    final cleanedOcr = data['_debug_cleaned_ocr'] as String?;
    final fields = Map<String, dynamic>.fromEntries(
      data.entries.where((e) => !e.key.startsWith('_debug_')),
    );

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / toggle
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.bug_report_outlined, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'DEBUG — OCR internals',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.amber,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            const Divider(color: Colors.amber, height: 1, thickness: 0.3),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Extracted fields table
                  _sectionTitle('Extracted fields'),
                  const SizedBox(height: 6),
                  ...fields.entries.map(
                    (e) => _fieldRow(e.key, e.value?.toString() ?? '–'),
                  ),

                  if (cleanedOcr != null && cleanedOcr.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _sectionTitle('Cleaned OCR text'),
                    const SizedBox(height: 6),
                    _textBlock(cleanedOcr),
                  ],

                  if (rawOcr != null && rawOcr.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _sectionTitle('Raw ML Kit output'),
                    const SizedBox(height: 6),
                    _textBlock(rawOcr),
                  ],

                  if (rawOcr == null && cleanedOcr == null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Raw/cleaned OCR text not available.\n'
                      'Check debugPrint() output in the IDE console.',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title.toUpperCase(),
    style: const TextStyle(
      color: Colors.amber,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      fontFamily: 'monospace',
    ),
  );

  Widget _fieldRow(String key, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            key,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    ),
  );

  Widget _textBlock(String text) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.black38,
      borderRadius: BorderRadius.circular(6),
    ),
    child: SelectableText(
      text,
      style: const TextStyle(
        color: Colors.lightGreenAccent,
        fontSize: 11,
        fontFamily: 'monospace',
        height: 1.4,
      ),
    ),
  );
}
