import 'package:bakid/fitur/admin/managemnt_guru/crud_guru.dart';
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
  bool _isSearching = false;
  List<Map<String, dynamic>> _guruList = [];
  List<Map<String, dynamic>> _filteredGuruList = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGuruList =
          query.isEmpty
              ? List.from(_guruList)
              : _guruList.where((guru) {
                final namaGuru =
                    guru['nama_lengkap']?.toString().toLowerCase() ?? '';
                final namaUser =
                    guru['pengguna']?['nama']?.toString().toLowerCase() ?? '';
                return namaGuru.contains(query) || namaUser.contains(query);
              }).toList();
    });
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('profil_guru')
          .select('*, pengguna(id, nama, peran)')
          .order('dibuat_pada', ascending: false);

      if (!mounted) return;

      setState(() {
        _guruList = List<Map<String, dynamic>>.from(response);
        _filteredGuruList = List.from(_guruList);
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Gagal memuat data: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteGuru(Map<String, dynamic> guru) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text(
              'Hapus guru ${guru['nama_lengkap']}? Akun pengguna juga akan dihapus.',
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

    if (confirmed != true) return;

    try {
      // Delete user account first (will cascade to profile via foreign key)
      await supabase.from('pengguna').delete().eq('id', guru['pengguna']['id']);

      if (mounted) {
        _showSuccessSnackbar('Data guru berhasil dihapus');
        await _fetchData();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Gagal hapus data: ${e.toString()}');
      }
    }
  }

  Future<void> _updateActiveStatus(String id, bool currentStatus) async {
    try {
      await supabase
          .from('profil_guru')
          .update({'is_active': !currentStatus})
          .eq('id', id);
      await _fetchData();
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Gagal mengubah status: ${e.toString()}');
      }
    }
  }

  void _showAddProfileDialog() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const AddEditGuruProfilePage(),
          ),
        )
        .then((_) => _fetchData());
  }

  void _showEditProfileDialog(Map<String, dynamic> guruData) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddEditGuruProfilePage(guruData: guruData),
          ),
        )
        .then((_) => _fetchData());
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildGuruCard(Map<String, dynamic> guru) {
    final bool isActive = guru['is_active'] ?? true;
    final user = guru['pengguna'] ?? {};
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      guru['foto_url'] != null
                          ? NetworkImage(guru['foto_url'])
                          : null,
                  child:
                      guru['foto_url'] == null
                          ? const Icon(Icons.person, size: 28)
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
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['nama'] ?? '-',
                        style: TextStyle(color: colors.outline, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _updateActiveStatus(guru['id'], isActive),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? colors.surfaceContainerHighest
                              : colors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(
                        color:
                            isActive
                                ? colors.onSurfaceVariant
                                : colors.onErrorContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.work_outline, 'Jabatan', guru['jabatan']),
            _buildInfoRow(
              Icons.phone_outlined,
              'Telepon',
              guru['nomor_telepon'],
            ),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Daerah',
              guru['asal_daerah'],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: colors.primary),
                  onPressed: () => _showEditProfileDialog(guru),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colors.error),
                  onPressed: () => _deleteGuru(guru),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value ?? '-',
              style: TextStyle(fontSize: 14, color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Cari guru...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  style: TextStyle(color: colors.onSurface),
                  cursorColor: colors.primary,
                  onChanged: (value) => setState(() {}),
                )
                : const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: colors.primary,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProfileDialog,
        mini: true,

        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredGuruList.isEmpty
              ? Center(
                child: Text(
                  'Belum ada data guru',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchData,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: _filteredGuruList.length,
                  itemBuilder:
                      (context, index) =>
                          _buildGuruCard(_filteredGuruList[index]),
                ),
              ),
    );
  }
}
