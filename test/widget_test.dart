// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:jungle_jumpping/main.dart';

void main() {
  testWidgets('Splash screen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const JungleJumpersApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('FETCHING JUNGLE GEMS...'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    await tester.pump(const Duration(seconds: 4));
  });
}
