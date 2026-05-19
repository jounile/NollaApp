import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nolla_mobile/main.dart';

void main() {
  testWidgets('App renders home page', (WidgetTester tester) async {
    await tester.pumpWidget(const NollaMobileApp());

    expect(find.text('NollaMobile'), findsOneWidget);
    expect(find.text('Welcome to NollaMobile'), findsOneWidget);
  });
}
