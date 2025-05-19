import 'package:flutter/material.dart';

class StatusAbsensiChip extends StatelessWidget {
  final String label;
  final int count;

  const StatusAbsensiChip({
    super.key,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $count'),
      backgroundColor: _getStatusColor(label),
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'hadir':
        return Colors.green;
      case 'izin':
        return Colors.orange;
      case 'alpa':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
