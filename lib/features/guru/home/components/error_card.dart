import 'package:flutter/material.dart';

class ErrorCard extends StatelessWidget {
  final String message;

  const ErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red[600])),
          ),
        ],
      ),
    );
  }
}
