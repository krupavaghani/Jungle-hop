// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:jungle_jumpping/main.dart';

void main() {
  testWidgets('Splash screen displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JungleJumpersApp());
    // Pump a few frames to let the widgets render (can't use pumpAndSettle
    // because animations repeat indefinitely)
    await tester.pump();
    await tester.pump();

    // Verify that the splash screen displays the app content.
    // The title is "Jungle\nJumpers" with a newline, so we check for the full text
    expect(find.text('Jungle\nJumpers'), findsOneWidget);
    expect(find.text('Adventure Awaits!'), findsOneWidget);
    expect(find.text('LOADING...'), findsOneWidget);

    // Advance time to complete the Future.delayed timer (3 seconds) to avoid
    // pending timer error when test ends
    await tester.pump(const Duration(seconds: 4));
  });
}
