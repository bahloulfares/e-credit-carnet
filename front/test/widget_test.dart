import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ccns/main.dart';
import 'package:ccns/screens/login_screen.dart';

void main() {
  testWidgets('App boots and shows login when not authenticated', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
