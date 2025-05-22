import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';
import 'package:bakid/fitur/guru/jurnal/components/jurnal_card.dart';
import 'package:bakid/fitur/guru/jurnal/jurnal_form.dart';
import 'package:bakid/fitur/guru/jurnal/jurnal_providers.dart';

class JurnalPage extends ConsumerWidget {
  const JurnalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final guruId = user?['profil']?['id'] as String?;

    if (guruId == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Guru ID tidak ditemukan',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'Riwayat Jurnal',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JurnalForm()),
              );
            },
          ),
        ],
      ),
      body: _buildJurnalHistoryTab(context, ref, guruId, theme),
    );
  }

  Widget _buildJurnalHistoryTab(
    BuildContext context,
    WidgetRef ref,
    String guruId,
    ThemeData theme,
  ) {
    final jurnalAsync = ref.watch(jurnalProvider(guruId));

    return RefreshIndicator(
      onRefresh: () => ref.refresh(jurnalProvider(guruId).future),
      child: jurnalAsync.when(
        loading:
            () => Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
        error:
            (error, stack) => Center(
              child: Text(
                'Error: $error',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        data: (jurnalList) {
          if (jurnalList.isEmpty) {
            return _buildEmptyState(theme);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: jurnalList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final jurnal = jurnalList[index];
              return JurnalCard(jurnal: jurnal);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.note_remove,
            size: 72,
            color: theme.colorScheme.onSurface.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada jurnal',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(100),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Klik tombol + untuk menambahkan jurnal baru',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }
}
