import 'package:flutter/material.dart';
class ThemeCard extends StatelessWidget {
  final String name;
  const ThemeCard({super.key, required this.name});
  @override Widget build(BuildContext context) => Card(child: ListTile(title: Text(name)));
}
