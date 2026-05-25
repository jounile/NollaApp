import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = await SessionService.load();
  runApp(NollaApp(session: session));
}

class NollaApp extends StatelessWidget {
  final ({String username, String token})? session;

  const NollaApp({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final s = session;
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
      home: s != null
          ? MainScreen(username: s.username, authToken: s.token)
          : const LoginScreen(),
    );
  }
}
