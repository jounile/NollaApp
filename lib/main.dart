import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const NollaApp());
}

class NollaApp extends StatelessWidget {
  const NollaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NollaApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
