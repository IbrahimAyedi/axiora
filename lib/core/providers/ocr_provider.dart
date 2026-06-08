import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ocr_service.dart';

/// Provider for OCR service (singleton)
final ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService();
});
