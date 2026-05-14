import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:sqflow_example/main.dart';
import 'package:sqflow_example/pages/reactive_todo_page.dart';
import 'package:sqflow_example/pages/social_feed_page.dart';
import 'package:sqflow_example/pages/validation_demo_page.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('SqflowShowcaseApp navigation smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SqflowShowcaseApp());

    // Verify that the NavigationBar is present.
    expect(find.byType(NavigationBar), findsOneWidget);

    // Initial page should be ValidationDemoPage.
    expect(find.byType(ValidationDemoPage), findsOneWidget);

    // Tap on the 'Social' tab.
    await tester.tap(find.text('Social'));
    await tester.pump(const Duration(milliseconds: 500));

    // SocialFeedPage should now be visible.
    expect(find.byType(SocialFeedPage), findsOneWidget);

    // Tap on the 'Todos' tab.
    await tester.tap(find.text('Todos'));
    await tester.pump(const Duration(milliseconds: 500));

    // ReactiveTodoPage should now be visible.
    expect(find.byType(ReactiveTodoPage), findsOneWidget);

    // Tap back to 'Validation' tab.
    await tester.tap(find.text('Validation'));
    await tester.pump(const Duration(milliseconds: 500));

    // ValidationDemoPage should be visible again.
    expect(find.byType(ValidationDemoPage), findsOneWidget);
  });
}
