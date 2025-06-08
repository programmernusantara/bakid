import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bakid/fitur/admin/kelas/jadwal_form_dialog.dart';
import 'package:bakid/fitur/admin/kelas/mata_pelajaran_form_dialog.dart';
import 'package:bakid/fitur/admin/kelas/provider_management_kelas.dart';

class KelasDetailPage extends ConsumerStatefulWidget {
  final String kelasId;

  const KelasDetailPage({super.key, required this.kelasId});

  @override
  ConsumerState<KelasDetailPage> createState() => _KelasDetailPageState();
}

class _KelasDetailPageState extends ConsumerState<KelasDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final kelasDetailAsync = ref.watch(kelasDetailProvider(widget.kelasId));
    final mataPelajaranAsync = ref.watch(
      mataPelajaranByKelasProvider(widget.kelasId),
    );
    final jadwalAsync = ref.watch(jadwalByKelasProvider(widget.kelasId));
    final jurnalAsync = ref.watch(jurnalByKelasProvider(widget.kelasId));
    final absensiAsync = ref.watch(rekapAbsensiByKelasProvider(widget.kelasId));

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: kelasDetailAsync.when(
          loading:
              () =>
                  Text('Loading...', style: TextStyle(color: colors.onSurface)),
          error:
              (error, stack) => Text(
                'Detail Kelas',
                style: TextStyle(color: colors.onSurface, fontSize: 16),
              ),
          data:
              (kelas) => Text(
                kelas['nama'],
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: colors.primary,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurface.withAlpha(100),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(
              iconMargin: EdgeInsets.zero,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.book_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Mapel'),
                ],
              ),
            ),
            Tab(
              iconMargin: EdgeInsets.zero,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Jadwal'),
                ],
              ),
            ),
            Tab(
              iconMargin: EdgeInsets.zero,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.note_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Jurnal'),
                ],
              ),
            ),
            Tab(
              iconMargin: EdgeInsets.zero,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Absensi'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMataPelajaranTab(mataPelajaranAsync, colors),
          _buildJadwalTab(jadwalAsync, colors),
          _buildJurnalTab(jurnalAsync, colors),
          _buildAbsensiTab(absensiAsync, colors),
        ],
      ),
    );
  }

  Widget _buildMataPelajaranTab(
    AsyncValue<List<Map<String, dynamic>>> mataPelajaranAsync,
    ColorScheme colors,
  ) {
    return mataPelajaranAsync.when(
      loading:
          () => Center(child: CircularProgressIndicator(color: colors.primary)),
      error:
          (error, stack) => Center(
            child: Text(
              'Terjadi kesalahan: $error',
              style: TextStyle(color: colors.error),
            ),
          ),
      data: (mataPelajaranList) {
        if (mataPelajaranList.isEmpty) {
          return Stack(
            children: [
              Center(
                child: Text(
                  'Tidak ada mata pelajaran',
                  style: TextStyle(color: colors.onSurface.withAlpha(100)),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () => _showMataPelajaranForm(context),
                  mini: true,
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          );
        }
        return Stack(
          children: [
            ListView.separated(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 80, // Beri ruang untuk FAB
              ),
              itemCount: mataPelajaranList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final mapel = mataPelajaranList[index];
                return Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colors.outline.withAlpha(100)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),

                    title: Text(
                      mapel['nama'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    subtitle:
                        mapel['deskripsi']?.isNotEmpty == true
                            ? Text(
                              mapel['deskripsi'],
                              style: TextStyle(color: colors.onSurfaceVariant),
                            )
                            : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: colors.primary,
                          ),
                          onPressed:
                              () => _showMataPelajaranForm(context, mapel),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: colors.error),
                          onPressed:
                              () => _showDeleteMataPelajaranDialog(
                                context,
                                mapel['id'],
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => _showMataPelajaranForm(context),
                mini: true,
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildJadwalTab(
    AsyncValue<List<Map<String, dynamic>>> jadwalAsync,
    ColorScheme colors,
  ) {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 8),
            Expanded(
              child: jadwalAsync.when(
                loading:
                    () => Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    ),
                error:
                    (error, stack) => Center(
                      child: Text(
                        'Terjadi kesalahan: $error',
                        style: TextStyle(color: colors.error),
                      ),
                    ),
                data: (jadwalList) {
                  if (jadwalList.isEmpty) {
                    return Center(
                      child: Text(
                        'Tidak ada jadwal',
                        style: TextStyle(
                          color: colors.onSurface.withAlpha(100),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: jadwalList.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final jadwal = jadwalList[index];
                      return Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: colors.outline.withAlpha(100),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),

                          title: Text(
                            '${_getHariName(jadwal['hari_dalam_minggu'])} - ${jadwal['mata_pelajaran']?['nama'] ?? '-'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${jadwal['waktu_mulai']} - ${jadwal['waktu_selesai']}',
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              if (jadwal['guru']?['nama_lengkap'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.person_outline,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              jadwal['guru']!['nama_lengkap'],
                                              style: TextStyle(
                                                color: colors.onSurfaceVariant,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (jadwal['guru']?['asal_daerah'] !=
                                                null)
                                              Text(
                                                jadwal['guru']!['asal_daerah'],
                                                style: TextStyle(
                                                  color:
                                                      colors.onSurfaceVariant,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (jadwal['lokasi_absen']?['nama'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          jadwal['lokasi_absen']!['nama'],
                                          style: TextStyle(
                                            color: colors.onSurfaceVariant,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: colors.primary,
                                ),
                                onPressed:
                                    () => _showJadwalForm(context, jadwal),
                                tooltip: 'Edit Jadwal',
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: colors.error,
                                ),
                                onPressed:
                                    () => _showDeleteJadwalDialog(
                                      context,
                                      jadwal['id'],
                                    ),
                                tooltip: 'Hapus Jadwal',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),

        // FAB Tambah Jadwal
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => _showJadwalForm(context),
            mini: true,
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            tooltip: 'Tambah Jadwal',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildJurnalTab(
    AsyncValue<List<Map<String, dynamic>>> jurnalAsync,
    ColorScheme colors,
  ) {
    return jurnalAsync.when(
      loading:
          () => Center(child: CircularProgressIndicator(color: colors.primary)),
      error:
          (error, stack) => Center(
            child: Text('Error: $error', style: TextStyle(color: colors.error)),
          ),
      data: (jurnalList) {
        if (jurnalList.isEmpty) {
          return Center(
            child: Text(
              'Tidak ada jurnal mengajar',
              style: TextStyle(color: colors.onSurface.withAlpha(100)),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: jurnalList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final jurnal = jurnalList[index];

            return Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.outline.withAlpha(100)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mata pelajaran dan tanggal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.book_outlined,
                              color: colors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              jurnal['jadwal']?['mata_pelajaran']?['nama'] ??
                                  '-',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatDate(jurnal['tanggal']),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    if (jurnal['guru']?['nama_lengkap'] != null)
                      Text(
                        '👤 ${jurnal['guru']?['nama_lengkap']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Materi
                    Row(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Materi yang Dipelajari:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      jurnal['materi_yang_dipelajari'] ?? '-',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),

                    // Kendala
                    if (jurnal['kendala']?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            size: 18,
                            color: colors.tertiary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Kendala:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        jurnal['kendala']!,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],

                    // Solusi
                    if (jurnal['solusi']?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 18,
                            color: colors.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Solusi:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        jurnal['solusi']!,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAbsensiTab(
    AsyncValue<List<Map<String, dynamic>>> absensiAsync,
    ColorScheme colors,
  ) {
    return absensiAsync.when(
      loading:
          () => Center(child: CircularProgressIndicator(color: colors.primary)),
      error:
          (error, stack) => Center(
            child: Text('Error: $error', style: TextStyle(color: colors.error)),
          ),
      data: (absensiList) {
        if (absensiList.isEmpty) {
          return Center(
            child: Text(
              'Tidak ada rekap absensi',
              style: TextStyle(color: colors.onSurface.withAlpha(100)),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: absensiList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final absensi = absensiList[index];
            return Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.outline.withAlpha(100)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul & Tanggal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.book, color: colors.primary, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              absensi['jadwal']?['mata_pelajaran']?['nama'] ??
                                  '-',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatDate(absensi['tanggal']),
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Guru
                    if (absensi['guru']?['nama_lengkap'] != null)
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Oleh: ${absensi['guru']?['nama_lengkap']}',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Rekap
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAbsensiIndicator(
                          'Hadir',
                          absensi['jumlah_hadir'],
                          colors.primary,
                          Icons.check_circle,
                        ),
                        _buildAbsensiIndicator(
                          'Izin',
                          absensi['jumlah_izin'],
                          colors.secondary,
                          Icons.info_outline,
                        ),
                        _buildAbsensiIndicator(
                          'Alpa',
                          absensi['jumlah_alpa'],
                          colors.error,
                          Icons.cancel,
                        ),
                      ],
                    ),

                    // Detail siswa izin/alpa
                    if (absensi['nama_izin']?.isNotEmpty == true ||
                        absensi['nama_alpa']?.isNotEmpty == true)
                      const SizedBox(height: 16),
                    if (absensi['nama_izin']?.isNotEmpty == true) ...[
                      Text(
                        'Siswa Izin:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        absensi['nama_izin']!,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                    if (absensi['nama_alpa']?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Siswa Alpa:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        absensi['nama_alpa']!,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAbsensiIndicator(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(100),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          '$label: $count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getHariName(int hari) {
    switch (hari) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return 'Tidak valid';
    }
  }

  String _formatDate(String date) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  Future<void> _showMataPelajaranForm(
    BuildContext context, [
    Map<String, dynamic>? mataPelajaranData,
  ]) async {
    final result = await showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MataPelajaranFormDialog(
                kelasId: widget.kelasId,
                mataPelajaranData: mataPelajaranData,
              ),
            ),
          ),
    );

    if (result == true) {
      ref.invalidate(mataPelajaranByKelasProvider(widget.kelasId));
    }
  }

  Future<void> _showJadwalForm(
    BuildContext context, [
    Map<String, dynamic>? jadwalData,
  ]) async {
    final result = await showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: JadwalFormDialog(
                kelasId: widget.kelasId,
                jadwalData: jadwalData,
              ),
            ),
          ),
    );

    if (result == true) {
      ref.invalidate(jadwalByKelasProvider(widget.kelasId));
    }
  }

  Future<void> _showDeleteMataPelajaranDialog(
    BuildContext context,
    String id,
  ) async {
    // Ambil ScaffoldMessenger sebelum operasi async
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Mata Pelajaran'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus mata pelajaran ini?',
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

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(mataPelajaranServiceProvider).deleteMataPelajaran(id);
      ref.invalidate(mataPelajaranByKelasProvider(widget.kelasId));

      messenger.showSnackBar(
        const SnackBar(content: Text('Mata pelajaran berhasil dihapus')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  Future<void> _showDeleteJadwalDialog(BuildContext context, String id) async {
    // Ambil ScaffoldMessenger sebelum operasi async
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Jadwal'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus jadwal ini?',
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

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(jadwalMengajarServiceProvider).deleteJadwal(id);
      ref.invalidate(jadwalByKelasProvider(widget.kelasId));

      messenger.showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil dihapus')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }
}
