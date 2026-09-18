import 'package:flutter/material.dart';
class StatusIndicator extends StatelessWidget {
  final String status;
  const StatusIndicator({super.key, required this.status});
  @override Widget build(BuildContext context) => Chip(label: Text(status));
}
