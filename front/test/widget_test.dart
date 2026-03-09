import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ccns/main.dart';

void main() {
  testWidgets('App boots and shows login when not authenticated', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsWidgets);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
