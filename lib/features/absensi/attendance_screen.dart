import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bakid/core/services/supabase_service.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  @override
  Widget build(BuildContext context) {
    final santriId = SupabaseService().currentUser?.id ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.grey[100],
          elevation: 0,
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(icon: Icon(Icons.today), text: 'Harian'),
              Tab(icon: Icon(Icons.calendar_month), text: 'Bulanan'),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TabBarView(
            children: [
              // Harian
              FutureBuilder<List<Map<String, dynamic>>>(
                future: SupabaseService().fetchDailyAttendance(santriId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.list_alt,
                      message: 'Belum ada data absensi',
                    );
                  }
                  return ListView.separated(
                    itemCount: snapshot.data!.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final absensi = snapshot.data![index];
                      return _buildDailyCard(absensi);
                    },
                  );
                },
              ),
              // Bulanan
              FutureBuilder<List<Map<String, dynamic>>>(
                future: SupabaseService().fetchMonthlyAttendance(santriId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.calendar_today,
                      message: 'Belum ada data rekap bulanan',
                    );
                  }
                  return ListView.separated(
                    itemCount: snapshot.data!.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final rekap = snapshot.data![index];
                      return _buildMonthlyCard(rekap);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildDailyCard(Map<String, dynamic> data) {
    final date = DateTime.parse(data['tanggal']);
    final formattedDate = '${date.day}/${date.month}/${date.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: _getStatusIcon(data['status']),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${_capitalize(data['status'])}',
                  style: TextStyle(color: _getStatusColor(data['status'])),
                ),
                if (data['keterangan'] != null &&
                    data['keterangan'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data['keterangan'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCard(Map<String, dynamic> data) {
    final total = data['total_hadir'] + data['total_izin'] + data['total_alpa'];
    final percent =
        total > 0
            ? (data['total_hadir'] / total * 100).toStringAsFixed(1)
            : '0.0';

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${data['bulan']}/${data['tahun']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIndicator('Hadir', data['total_hadir'], Colors.green),
              _buildIndicator('Izin', data['total_izin'], Colors.orange),
              _buildIndicator('Alpa', data['total_alpa'], Colors.red),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hadir $percent%',
            style: TextStyle(color: _getPercentageColor(double.parse(percent))),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'hadir':
        return const Icon(Icons.check, color: Colors.green, size: 20);
      case 'izin':
        return const Icon(Icons.info, color: Colors.orange, size: 20);
      case 'alpa':
        return const Icon(Icons.close, color: Colors.red, size: 20);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey, size: 20);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'hadir':
        return Colors.green;
      case 'izin':
        return Colors.orange;
      case 'alpa':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPercentageColor(double percent) {
    if (percent >= 90) return Colors.green;
    if (percent >= 70) return Colors.orange;
    return Colors.red;
  }

  String _capitalize(String text) =>
      text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';
}
