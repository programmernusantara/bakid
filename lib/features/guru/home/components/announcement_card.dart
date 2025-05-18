import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnnouncementCard extends StatelessWidget {
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime? date;

  const AnnouncementCard({
    super.key,
    required this.title,
    required this.content,
    this.imageUrl,
    this.date,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(100),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.campaign_outlined,
                  size: 18,
                  color: Colors.orange.withAlpha(100),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (date != null)
                Text(
                  DateFormat('dd/MM/yy').format(date!),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(color: Colors.grey[800], fontSize: 14),
          ),
          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl!,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
