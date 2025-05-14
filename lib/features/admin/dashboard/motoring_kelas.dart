// monitoring_screen.dart
import 'package:bakid/features/admin/providers/monitoring_kelas_provider.dart';
import 'package:bakid/models/monitoring_kelas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MonitoringScreen extends ConsumerWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitoringStream = ref.watch(monitoringKelasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Kelas Real-time'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(monitoringKelasProvider),
          ),
        ],
      ),
      body: monitoringStream.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (List<MonitoringKelas> data) {
          if (data.isEmpty) {
            return const Center(child: Text('Tidak ada jadwal hari ini'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final jadwal = data[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            jadwal.kelas,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(jadwal.jamPelajaran),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Guru: ${jadwal.guru}'),
                      Text('Mata Pelajaran: ${jadwal.mataPelajaran}'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Kehadiran: '),
                          Text(jadwal.kehadiran),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Jurnal: ${jadwal.jurnal}'),
                      const SizedBox(height: 8),
                      Text(
                        'Terakhir update: ${jadwal.lastUpdate.toLocal().toString().substring(11, 16)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
