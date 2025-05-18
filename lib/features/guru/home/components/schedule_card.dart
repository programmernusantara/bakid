import 'package:flutter/material.dart';

class ScheduleCard extends StatelessWidget {
  final String subject;
  final String kelas;
  final String time;

  const ScheduleCard({
    super.key,
    required this.subject,
    required this.kelas,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withAlpha(100),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_outlined,
              color: Colors.blueAccent.withAlpha(100),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  kelas,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time.split('-')[0].trim(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent.withAlpha(100),
                ),
              ),
              Text(
                time.split('-')[1].trim(),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
