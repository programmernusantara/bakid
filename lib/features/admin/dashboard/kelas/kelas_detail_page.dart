// features/admin/dashboard/kelas/kelas_detail_page.dart
import 'package:bakid/features/admin/dashboard/kelas/kelas_model.dart';
import 'package:bakid/features/admin/dashboard/kelas/kelas_provider.dart';
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
              return _JurnalCard(jurnal: jurnal);
            },
          ),
        );
      },
    );
  }
}

class _JurnalCard extends StatelessWidget {
  final JurnalMengajar jurnal;

  const _JurnalCard({required this.jurnal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    jurnal.mataPelajaran,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Materi Pembelajaran',
              style: textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(jurnal.materi, style: textTheme.bodyMedium),
            if (jurnal.kendala != null) ...[
              const SizedBox(height: 12),
              Text(
                'Kendala',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    size: 16,
                    color: colors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      jurnal.kendala!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (jurnal.solusi != null) ...[
              const SizedBox(height: 12),
              Text(
                'Solusi',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outlined,
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      jurnal.solusi!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
                  'Tambahkan data absensi untuk memulai',
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
              return _AbsensiCard(absensi: absensi);
            },
          ),
        );
      },
    );
  }
}

class _AbsensiCard extends StatelessWidget {
  final RekapAbsensi absensi;

  const _AbsensiCard({required this.absensi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                  _formatDate(absensi.tanggal),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                if (absensi.mataPelajaran != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      absensi.mataPelajaran!,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onTertiaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatusIndicator(
                  icon: Icons.check_circle_outlined,
                  color: colors.primary,
                  count: absensi.hadir,
                  label: 'Hadir',
                ),
                _StatusIndicator(
                  icon: Icons.mail_outlined,
                  color: colors.secondary,
                  count: absensi.izin,
                  label: 'Izin',
                ),
                _StatusIndicator(
                  icon: Icons.highlight_off_outlined,
                  color: colors.error,
                  count: absensi.alpa,
                  label: 'Alpa',
                ),
              ],
            ),
            if (absensi.namaIzin != null || absensi.namaAlpa != null) ...[
              const SizedBox(height: 16),
              if (absensi.namaIzin != null) ...[
                Text(
                  'Siswa Izin',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  absensi.namaIzin!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.secondary,
                  ),
                ),
              ],
              if (absensi.namaAlpa != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Siswa Alpa',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  absensi.namaAlpa!,
                  style: textTheme.bodyMedium?.copyWith(color: colors.error),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _StatusIndicator extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String label;

  const _StatusIndicator({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
