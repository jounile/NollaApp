import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/session_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NollaApp());
}

class NollaApp extends StatefulWidget {
  const NollaApp({super.key});

  @override
  State<NollaApp> createState() => _NollaAppState();
}

class _NollaAppState extends State<NollaApp> {
  ({String username, String token})? _session;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    SessionService.load().then((s) {
      if (mounted) setState(() { _session = s; _loaded = true; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NollaApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: !_loaded
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _session != null
              ? MainScreen(username: _session!.username, authToken: _session!.token)
              : const LoginScreen(),
    );
  }
}
