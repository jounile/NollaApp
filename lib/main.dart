import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/session_service.dart';
import 'services/theme_service.dart';
import 'utils/app_theme.dart';

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
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _themeService.addListener(_onThemeChanged);
    _load();
  }

  Future<void> _load() async {
    await _themeService.load();
    final session = await SessionService.load();
    if (mounted) {
      setState(() {
        _session = session;
        _loaded = true;
      });
    }
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NollaApp',
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: _themeService.mode,
      home: !_loaded
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _session != null
              ? MainScreen(
                  username: _session!.username,
                  authToken: _session!.token,
                  themeService: _themeService,
                )
              : const LoginScreen(),
    );
  }
}
