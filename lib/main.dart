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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: s != null
          ? MainScreen(username: s.username, authToken: s.token)
          : const LoginScreen(),
    );
  }
}
