import 'package:flutter/material.dart';
import 'screens/home.dart';

void main() {
  runApp(const AshApp());
}

class AshApp extends StatelessWidget {
  const AshApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASH',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF7C3AED)),
      home: const HomeScreen(),
    );
  }
}
