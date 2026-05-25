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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ).copyWith(
          primary: Colors.orange,
          onPrimary: Colors.black,
          primaryContainer: const Color(0xFF3D2000),
          onPrimaryContainer: Colors.orange,
          secondary: Colors.deepOrange,
          onSecondary: Colors.black,
          secondaryContainer: const Color(0xFF2D1200),
          onSecondaryContainer: Colors.deepOrange,
          surface: const Color(0xFF121212),
          onSurface: Colors.white,
          surfaceContainerHighest: const Color(0xFF1E1E1E),
          onSurfaceVariant: Colors.orange,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
