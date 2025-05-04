import 'package:bakid/app/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RaportScreen extends ConsumerWidget {
  const RaportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final supabase = ref.read(supabaseClientProvider);

    return Scaffold(
      body: authState.when(
        loading:
            () => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
              ),
            ),
        error: (err, _) => _buildErrorWidget('$err'),
        data: (user) {
          if (user == null) {
            return _buildMessageWidget(
              icon: LucideIcons.logIn,
              message: 'Silakan login terlebih dahulu',
            );
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: supabase.fetchAcademicRecords(user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorWidget(
                  '${snapshot.error}',
                  subtitle: 'Gagal memuat data akademik',
                  onRetry: () => ref.invalidate(supabaseClientProvider),
                );
              }

              final academics = snapshot.data ?? [];

              if (academics.isEmpty) {
                return _buildMessageWidget(
                  icon: LucideIcons.fileText,
                  message: 'Belum ada data akademik',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: academics.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final academic = academics[index];
                  final scoreColor = _getScoreColor(academic['nilai']);
                  final lightColor = _getLightVariant(scoreColor);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Semester ${academic['semester']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: lightColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: scoreColor),
                              ),
                              child: Text(
                                'Nilai: ${academic['nilai']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: scoreColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Colors.grey),
                        const SizedBox(height: 12),

                        // Informasi akademik
                        _buildInfoRow(
                          icon: LucideIcons.award,
                          label: 'Peringkat',
                          value: '${academic['peringkat']}',
                        ),
                        _buildInfoRow(
                          icon: LucideIcons.users,
                          label: 'Jumlah Siswa',
                          value: '${academic['total_santri']}',
                        ),
                        if (academic['catatan'] != null &&
                            academic['catatan'].toString().trim().isNotEmpty)
                          _buildInfoRow(
                            icon: LucideIcons.clipboardList,
                            label: 'Catatan',
                            value: academic['catatan'].toString(),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageWidget({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(
    String error, {
    String? subtitle,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: Colors.red[400]),
          if (subtitle != null) ...[
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blueGrey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
              ),
              onPressed: onRetry,
              child: Text(
                'Coba Lagi',
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getScoreColor(dynamic score) {
    try {
      final value =
          score is int
              ? score.toDouble()
              : score is double
              ? score
              : double.tryParse(score.toString()) ?? 0.0;

      if (value >= 85) return Colors.green[800]!;
      if (value >= 70) return Colors.blue[800]!;
      if (value >= 55) return Colors.orange[800]!;
      return Colors.red[800]!;
    } catch (e) {
      debugPrint('Error parsing score: $e');
      return Colors.grey;
    }
  }

  Color _getLightVariant(Color baseColor) {
    if (baseColor == Colors.green[800]) return Colors.green[50]!;
    if (baseColor == Colors.blue[800]) return Colors.blue[50]!;
    if (baseColor == Colors.orange[800]) return Colors.orange[50]!;
    if (baseColor == Colors.red[800]) return Colors.red[50]!;
    return Colors.grey[50]!;
  }
}
