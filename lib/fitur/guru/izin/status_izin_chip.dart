// status_izin_chip.dart
import 'package:flutter/material.dart';

class StatusIzinChip extends StatelessWidget {
  final String status;

  const StatusIzinChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withAlpha(100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status).withAlpha(100),
          width: 1,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return const Color(0xFF00A86B); // Green
      case 'ditolak':
        return const Color(0xFFF04438); // Red
      case 'menunggu':
        return const Color(0xFFF79009); // Orange
      default:
        return const Color(0xFF667085); // Gray
    }
  }
}
