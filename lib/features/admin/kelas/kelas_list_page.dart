import 'package:bakid/features/admin/kelas/kelas_detail_page.dart';
import 'package:bakid/features/admin/kelas/kelas_model.dart';
import 'package:bakid/features/admin/kelas/kelas_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KelasListPage extends ConsumerWidget {
  const KelasListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final kelasAsync = ref.watch(daftarKelasProvider);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
            tooltip: 'Cari kelas',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: kelasAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, _) =>
                  ErrorState(onRetry: () => ref.refresh(daftarKelasProvider)),
          data: (kelasList) => KelasListView(kelasList: kelasList),
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const ErrorState({required this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.error),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat data kelas',
            style: theme.textTheme.bodyLarge?.copyWith(color: colors.error),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class KelasListView extends StatelessWidget {
  final List<Kelas> kelasList;

  const KelasListView({required this.kelasList, super.key});

  @override
  Widget build(BuildContext context) {
    if (kelasList.isEmpty) {
      return const EmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => Future.value(), // Add your refresh logic here
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: kelasList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => KelasCard(kelas: kelasList[index]),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: colors.outline),
          const SizedBox(height: 16),
          Text(
            'Belum ada kelas tersedia',
            style: theme.textTheme.titleMedium?.copyWith(color: colors.outline),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan kelas baru untuk memulai',
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.outline),
          ),
        ],
      ),
    );
  }
}

class KelasCard extends ConsumerWidget {
  final Kelas kelas;

  const KelasCard({required this.kelas, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant.withAlpha(127)),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ref.read(selectedKelasProvider.notifier).state = kelas;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KelasDetailPage()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
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
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer.withAlpha(127),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      kelas.tahunAjaran ?? '-',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Info row
              Row(
                children: [
                  InfoChip(
                    icon: Icons.person_outline,
                    label: kelas.waliKelas ?? 'Belum ada wali',
                    color: colors.primary,
                  ),
                  const SizedBox(width: 12),
                  InfoChip(
                    icon: Icons.people_outline,
                    label: '${kelas.jumlahMurid ?? 0} siswa',
                    color: colors.secondary,
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 20, color: colors.outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
