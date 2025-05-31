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

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and date first
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMM y, HH:mm').format(date!),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),

          // Image in the middle
          if (imageUrl != null)
            GestureDetector(
              onTap: () => _showFullScreenImage(context, imageUrl!),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(0),
                ),
                child: Image.network(
                  imageUrl!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                ),
              ),
            ),

          // Description/content at the bottom
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: TextStyle(color: Colors.grey[800], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
