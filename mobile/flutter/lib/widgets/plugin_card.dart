import 'package:flutter/material.dart';
class PluginCard extends StatelessWidget {
  final String name;
  const PluginCard({super.key, required this.name});
  @override Widget build(BuildContext context) => Card(child: ListTile(title: Text(name)));
}
