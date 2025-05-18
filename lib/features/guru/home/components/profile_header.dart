import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? user;

  const ProfileHeader({super.key, required this.profile, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (profile?['foto_url'] != null)
            CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage(profile!['foto_url']),
            )
          else
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.grey[200],
              child: Icon(Icons.person, color: Colors.grey[600], size: 30),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?['nama_lengkap'] ?? user?['nama'] ?? 'Guru',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?['asal_daerah'] ?? '-',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
