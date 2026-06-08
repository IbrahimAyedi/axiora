# OCR Integration Examples

This file intentionally stores OCR examples as documentation, not as executable Dart source.

Reason:
- A previous `OCR_INTEGRATION_EXAMPLES.dart` file was treated as production/analyzed code.
- That example file contained incomplete snippets and non-production directives/imports.
- Keeping examples in Markdown prevents analyzer/build breakage.

Production OCR implementation lives in:
- `lib/core/models/ocr_result.dart`
- `lib/core/services/ocr_service.dart`
- `lib/core/providers/ocr_provider.dart`
- `lib/features/scan/presentation/screens/ocr_test_screen.dart`

Router integration lives in:
- `lib/app/router/app_router.dart`

Use package imports in production files where possible, and keep sample snippets in Markdown docs only.
