import 'package:bakid/fitur/admin/pengumuman/pengumuman_form.dart';
import 'package:bakid/fitur/admin/pengumuman/pengumuman_service.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PengumumanListPage extends ConsumerStatefulWidget {
  const PengumumanListPage({super.key});

  @override
  ConsumerState<PengumumanListPage> createState() => _PengumumanListPageState();
}

class _PengumumanListPageState extends ConsumerState<PengumumanListPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pengumumanList = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final pengumumanService = ref.read(pengumumanServiceProvider);
      final data = await pengumumanService.getPengumuman();
      if (mounted) {
        setState(() => _pengumumanList = data);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showFullScreenImage(String imageUrl) {
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

  Widget _buildPengumumanCard(Map<String, dynamic> pengumuman) {
    final bool isActive = pengumuman['aktif'] ?? true;
    final adminName =
        pengumuman['admin_id'] != null
            ? (pengumuman['admin_id'] as Map<String, dynamic>)['nama']
            : 'Admin';
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final createdAt = DateTime.parse(pengumuman['dibuat_pada']).toLocal();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    pengumuman['judul'] ?? 'No Title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isActive ? 'AKTIF' : 'NONAKTIF',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (pengumuman['foto_url'] != null)
              GestureDetector(
                onTap: () => _showFullScreenImage(pengumuman['foto_url']),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    pengumuman['foto_url'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                  ),
                ),
              ),

            const SizedBox(height: 12),
            Text(
              pengumuman['isi'] ?? 'No Content',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Footer dengan info admin dan tanggal
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Oleh: $adminName',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    dateFormat.format(createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Action buttons
            if (ref.watch(currentUserProvider)?['peran'] == 'admin')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: Colors.blue,
                    onPressed: () => _editPengumuman(pengumuman),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red,
                    onPressed: () => _confirmDelete(pengumuman['id']),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editPengumuman(Map<String, dynamic> pengumuman) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PengumumanFormPage(initialData: pengumuman),
      ),
    );

    if (result == true && mounted) {
      await _fetchData();
    }
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus pengumuman ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      await _deletePengumuman(id);
    }
  }

  Future<void> _deletePengumuman(String id) async {
    try {
      final pengumumanService = ref.read(pengumumanServiceProvider);
      await pengumumanService.deletePengumuman(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengumuman berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchData();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Gagal menghapus: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (currentUser != null && currentUser['peran'] == 'admin')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            PengumumanFormPage(adminId: currentUser['id']),
                  ),
                );

                if (result == true && mounted) {
                  await _fetchData();
                }
              },
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _pengumumanList.isEmpty
              ? const Center(
                child: Text(
                  'Belum ada pengumuman',
                  style: TextStyle(color: Colors.grey),
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchData,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 16, bottom: 24),
                  itemCount: _pengumumanList.length,
                  itemBuilder:
                      (context, index) =>
                          _buildPengumumanCard(_pengumumanList[index]),
                ),
              ),
    );
  }
}
