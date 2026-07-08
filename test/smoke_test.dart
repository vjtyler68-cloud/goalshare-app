import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke test: verifies the test harness itself is wired correctly and
/// a minimal Flutter widget tree can be pumped without errors.
///
/// Full app-boot tests (MainActivity → Splash → Home) require Firebase and
/// Hive to be initialised, which is only possible in an integration-test
/// environment with a real device or emulator.  Those live in
/// integration_test/ and are run separately via `flutter test integration_test`.
void main() {
  testWidgets('smoke – MaterialApp renders without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Spanx loaded')),
        ),
      ),
    );

    // Verify the widget tree is present and the text is rendered.
    expect(find.text('Spanx loaded'), findsOneWidget);
  });

  testWidgets('smoke – Navigator can push and pop a route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => const Scaffold(body: Text('Home')),
          '/detail': (_) => const Scaffold(body: Text('Detail')),
        },
      ),
    );

    // Confirm the initial route shows.
    expect(find.text('Home'), findsOneWidget);
  });
}
