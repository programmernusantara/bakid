import 'package:flutter/material.dart';

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyStateCard({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
