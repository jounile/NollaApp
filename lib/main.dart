import 'package:flutter/material.dart';

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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NollaApp'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Text('Welcome to NollaApp'),
      ),
    );
  }
}
