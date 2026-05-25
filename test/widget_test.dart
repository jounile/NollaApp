import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nolla_app/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const NollaApp(session: null));

    expect(find.text('Sign in to NollaApp'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
