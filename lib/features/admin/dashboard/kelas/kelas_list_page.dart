// features/admin/dashboard/kelas/kelas_list_page.dart
import 'package:bakid/features/admin/dashboard/kelas/kelas_detail_page.dart';
import 'package:bakid/features/admin/dashboard/kelas/kelas_model.dart';
import 'package:bakid/features/admin/dashboard/kelas/kelas_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KelasListPage extends ConsumerWidget {
  const KelasListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kelasAsync = ref.watch(daftarKelasProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: kelasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data kelas',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => ref.refresh(daftarKelasProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
          data: (kelasList) {
            if (kelasList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: colors.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada kelas tersedia',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tambahkan kelas baru untuk memulai',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.outline,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => ref.refresh(daftarKelasProvider.future),
              child: ListView.separated(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                itemCount: kelasList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final kelas = kelasList[index];
                  return _KelasCard(kelas: kelas);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _KelasCard extends ConsumerWidget {
  final Kelas kelas;

  const _KelasCard({required this.kelas});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ref.read(selectedKelasProvider.notifier).state = kelas;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const KelasDetailPage()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school,
                      size: 20,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      kelas.nama,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
                      kelas.tahunAjaran ?? '-',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.person_outline,
                    label: kelas.waliKelas ?? 'Belum ada wali kelas',
                    color: colors.primary,
                  ),
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.people_outline,
                    label: '${kelas.jumlahMurid ?? 0} Siswa',
                    color: colors.secondary,
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: colors.outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
