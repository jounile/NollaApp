import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'spots_screen.dart';
import 'media_screen.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  final String username;
  final String authToken;

  const MainScreen({super.key, required this.username, required this.authToken});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    HomeScreen(username: widget.username),
    const SpotsScreen(),
    MediaScreen(authToken: widget.authToken),
  ];

  void _onItemTapped(int index) {
    if (index == 3) {
      _confirmLogout();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const LoginScreen(),
                ),
                (_) => false,
              );
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Spots',
          ),
          NavigationDestination(
            icon: Icon(Icons.perm_media_outlined),
            selectedIcon: Icon(Icons.perm_media),
            label: 'Media',
          ),
          NavigationDestination(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
}
