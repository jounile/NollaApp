import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nolla_app/main.dart';

void main() {
  testWidgets('App renders home page', (WidgetTester tester) async {
    await tester.pumpWidget(const NollaApp());

    expect(find.text('NollaApp'), findsOneWidget);
    expect(find.text('Welcome to NollaApp'), findsOneWidget);
  });
}
