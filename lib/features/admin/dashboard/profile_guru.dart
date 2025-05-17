import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuruManagementPage extends ConsumerStatefulWidget {
  const GuruManagementPage({super.key});

  @override
  ConsumerState<GuruManagementPage> createState() => _GuruManagementPageState();
}

class _GuruManagementPageState extends ConsumerState<GuruManagementPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _guruList = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('profil_guru')
          .select('*, pengguna(id, nama)')
          .order('dibuat_pada', ascending: false);
      if (mounted) {
        setState(() {
          _guruList = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildGuruCard(Map<String, dynamic> guru) {
    final bool isActive = guru['is_active'] ?? true;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Header dengan foto dan nama
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage:
                      guru['foto_url'] != null
                          ? NetworkImage(guru['foto_url'])
                          : null,
                  child:
                      guru['foto_url'] == null
                          ? const Icon(Icons.person, size: 30)
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guru['nama_lengkap'] ?? '-',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Aktif' : 'Tidak Aktif',
                    style: TextStyle(
                      color: isActive ? Colors.green[800] : Colors.red[800],
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 1.2),
            _buildInfoRow(Icons.badge_outlined, 'Jabatan', guru['jabatan']),
            const Divider(thickness: 1.2),
            _buildInfoRow(
              Icons.phone_outlined,
              'Telepon',
              guru['nomor_telepon'],
            ),
            const Divider(thickness: 1.2),
            _buildInfoRow(
              Icons.location_city_outlined,
              'Daerah',
              guru['asal_daerah'],
            ),
            const Divider(thickness: 1.2),
            _buildInfoRow(Icons.home_outlined, 'Alamat', guru['alamat']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: '$label: ',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: value ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _guruList.isEmpty
              ? const Center(child: Text('Belum ada data guru'))
              : RefreshIndicator(
                onRefresh: _fetchData,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: _guruList.length,
                  itemBuilder:
                      (context, index) => _buildGuruCard(_guruList[index]),
                ),
              ),
    );
  }
}
