import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:omr_mobile_app/main.dart';

void main() {
  testWidgets('OMRScanApp smoke test', (WidgetTester tester) async {
    // Build our app and advance frames past splash timers (600ms+)
    await tester.pumpWidget(const ProviderScope(child: OMRScanApp()));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(seconds: 1));

    // Verify that the app mounts
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
