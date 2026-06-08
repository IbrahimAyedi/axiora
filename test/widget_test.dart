import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_constat/app/app.dart';

void main() {
  testWidgets('App bootstraps splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Splash Screen'), findsOneWidget);
  });
}
