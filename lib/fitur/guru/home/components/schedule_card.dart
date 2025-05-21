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
    final times = time.split('-');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigo.withAlpha(100),
            child: Icon(Icons.schedule, color: Colors.indigo),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(kelas, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                times[0].trim(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              Text(
                times[1].trim(),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
