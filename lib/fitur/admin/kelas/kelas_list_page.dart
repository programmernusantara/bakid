import 'package:bakid/fitur/admin/kelas/kelas_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bakid/fitur/admin/kelas/kelas_detail_page.dart';
import 'package:bakid/fitur/admin/kelas/provider_management_kelas.dart';

class KelasListPage extends ConsumerStatefulWidget {
  const KelasListPage({super.key});

  @override
  ConsumerState<KelasListPage> createState() => _KelasListPageState();
}

class _KelasListPageState extends ConsumerState<KelasListPage> {
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final kelasListAsync = ref.watch(kelasListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Cari kelas...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  style: TextStyle(color: colors.onSurface),
                  cursorColor: colors.primary,
                  onChanged: (value) => setState(() {}),
                )
                : null,
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

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: kelasListAsync.when(
          loading:
              () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          error:
              (error, _) => Center(
                child: Text(
                  'Gagal memuat data\n$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.error),
                ),
              ),
          data: (kelasList) {
            final filteredList =
                kelasList.where((kelas) {
                  return kelas['nama'].toString().toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  );
                }).toList();

            if (filteredList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.class_outlined,
                      size: 48,
                      color: colors.onSurface.withAlpha(100),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchController.text.isEmpty
                          ? 'Belum ada kelas'
                          : 'Tidak ada kelas ditemukan',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Text('Reset pencarian'),
                      ),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: filteredList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final kelas = filteredList[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              kelas['nama'],
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.visibility_outlined,
                                  size: 20,
                                  color: colors.primary,
                                ),
                                onPressed: () {
                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => KelasDetailPage(
                                              kelasId: kelas['id'],
                                            ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: colors.primary,
                                ),
                                onPressed: () {
                                  if (mounted) {
                                    _showKelasForm(context, kelas);
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outlined,
                                  size: 20,
                                  color: colors.error,
                                ),
                                onPressed: () {
                                  if (mounted) {
                                    _showDeleteDialog(context, kelas['id']);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.person_outline,
                        'Wali Kelas: ${kelas['wali_kelas'] ?? '-'}',
                        colors,
                      ),
                      _buildInfoRow(
                        Icons.calendar_today_outlined,
                        'Tahun Ajaran: ${kelas['tahun_ajaran']}',
                        colors,
                      ),
                      _buildInfoRow(
                        Icons.people_outline,
                        'Jumlah Murid: ${kelas['jumlah_murid'] ?? 0}',
                        colors,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (mounted) {
            _showKelasForm(context);
          }
        },
        mini: true,
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _showKelasForm(
    BuildContext context, [
    Map<String, dynamic>? kelasData,
  ]) async {
    final result = await showDialog(
      context: context,
      builder:
          (_) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: KelasFormDialog(kelasData: kelasData),
            ),
          ),
    );

    if (!mounted) return;

    if (result == true) {
      ref.invalidate(kelasListProvider);
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, String id) async {
    // Ambil instance yang butuh context sebelum await
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Hapus Kelas'),
            content: const Text('Apakah Anda yakin ingin menghapus kelas ini?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await ref.read(kelasServiceProvider).deleteKelas(id);
        ref.invalidate(kelasListProvider);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Kelas berhasil dihapus'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus kelas: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
