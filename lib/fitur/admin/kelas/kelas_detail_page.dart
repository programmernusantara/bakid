import 'package:bakid/fitur/admin/kelas/kelas_model.dart';
import 'package:bakid/fitur/admin/kelas/kelas_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KelasDetailPage extends ConsumerStatefulWidget {
  const KelasDetailPage({super.key});

  @override
  ConsumerState<KelasDetailPage> createState() => _KelasDetailPageState();
}

class _KelasDetailPageState extends ConsumerState<KelasDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedKelas = ref.watch(selectedKelasProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (selectedKelas == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Kelas tidak ditemukan')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Kelas ${selectedKelas.nama}'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurfaceVariant,
          indicatorColor: colors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.book_outlined), text: 'Jurnal'),
            Tab(icon: Icon(Icons.assignment_outlined), text: 'Absensi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _JurnalTab(kelasId: selectedKelas.id),
          _AbsensiTab(kelasId: selectedKelas.id),
        ],
      ),
    );
  }
}

class _JurnalTab extends ConsumerWidget {
  final String kelasId;

  const _JurnalTab({required this.kelasId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jurnalAsync = ref.watch(jurnalKelasProvider(kelasId));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return jurnalAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colors.error),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat jurnal',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.error,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => ref.refresh(jurnalKelasProvider(kelasId)),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
      data: (jurnalList) {
        if (jurnalList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book_outlined, size: 64, color: colors.outline),
                const SizedBox(height: 16),
                Text(
                  'Belum ada jurnal pembelajaran',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tambahkan jurnal baru untuk memulai',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.outline,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(jurnalKelasProvider(kelasId).future),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: jurnalList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final jurnal = jurnalList[index];
              return JurnalCard(jurnal: jurnal);
            },
          ),
        );
      },
    );
  }
}

class JurnalCard extends StatelessWidget {
  final JurnalMengajar jurnal;

  const JurnalCard({super.key, required this.jurnal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(jurnal.tanggal),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    jurnal.mataPelajaran,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1),

            _buildInfoRow(
              Icons.menu_book_outlined,
              'Materi',
              jurnal.materi,
              colors.primary,
            ),

            if (jurnal.kendala != null) ...[
              const Divider(height: 16, thickness: 1),
              _buildInfoRow(
                Icons.warning_amber_outlined,
                'Kendala',
                jurnal.kendala!,
                colors.error,
              ),
            ],

            if (jurnal.solusi != null) ...[
              const Divider(height: 16, thickness: 1),
              _buildInfoRow(
                Icons.check_circle_outlined,
                'Solusi',
                jurnal.solusi!,
                colors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color.alphaBlend(color.withAlpha(204), Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _AbsensiTab extends ConsumerWidget {
  final String kelasId;

  const _AbsensiTab({required this.kelasId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final absensiAsync = ref.watch(absensiKelasProvider(kelasId));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return absensiAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colors.error),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat data absensi',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.error,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => ref.refresh(absensiKelasProvider(kelasId)),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
      data: (absensiList) {
        if (absensiList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: colors.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data absensi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Absensi akan muncul setelah data tersedia',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.outline,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(absensiKelasProvider(kelasId).future),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: absensiList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final absensi = absensiList[index];
              return AbsensiCard(absensi: absensi);
            },
          ),
        );
      },
    );
  }
}

class AbsensiCard extends StatelessWidget {
  final RekapAbsensi absensi;

  const AbsensiCard({super.key, required this.absensi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan tanggal
            Text(
              _formatDate(absensi.tanggal),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Statistik kehadiran
            Row(
              children: [
                _buildStatisticItem(
                  'Hadir',
                  absensi.hadir.toString(),
                  colors.primary,
                ),
                const SizedBox(width: 12),
                _buildStatisticItem(
                  'Izin',
                  absensi.izin.toString(),
                  colors.secondary,
                ),
                const SizedBox(width: 12),
                _buildStatisticItem(
                  'Alpa',
                  absensi.alpa.toString(),
                  colors.error,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1),

            // Daftar nama yang izin (jika ada)
            if (absensi.namaIzin != null && absensi.namaIzin!.isNotEmpty)
              _buildNameList(
                'Nama Yang Izin',
                absensi.namaIzin!,
                colors.secondary,
              ),

            // Daftar nama yang alpa (jika ada)
            if (absensi.namaAlpa != null && absensi.namaAlpa!.isNotEmpty)
              _buildNameList('Nama Yang Alpa', absensi.namaAlpa!, colors.error),

            // Keterangan (jika ada)
            if (absensi.keterangan != null && absensi.keterangan!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildInfoRow(
                  Icons.info_outline,
                  'Keterangan',
                  absensi.keterangan!,
                  colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Color.alphaBlend(color.withAlpha(25), Colors.white),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildNameList(String title, String names, Color color) {
    final nameList = names.split(',').map((e) => e.trim()).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children:
                nameList.map((name) {
                  return Chip(
                    label: Text(name),
                    backgroundColor: Color.alphaBlend(
                      color.withAlpha(25),
                      Colors.white,
                    ),
                    labelStyle: TextStyle(color: color),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Color.alphaBlend(
                          color.withAlpha(76),
                          Colors.white,
                        ),
                        width: 1,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color.alphaBlend(color.withAlpha(204), Colors.white),
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 14, color: color)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
