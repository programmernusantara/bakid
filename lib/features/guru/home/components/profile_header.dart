import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? user;

  const ProfileHeader({super.key, required this.profile, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage:
                profile?['foto_url'] != null
                    ? NetworkImage(profile!['foto_url'])
                    : null,
            backgroundColor: Colors.grey[200],
            child:
                profile?['foto_url'] == null
                    ? Icon(Icons.person, size: 30, color: Colors.grey[600])
                    : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?['nama_lengkap'] ?? user?['nama'] ?? 'Guru',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
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
