// jurnal_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:bakid/features/auth/auth_providers.dart';
import 'package:bakid/features/guru/jurnal/components/jurnal_card.dart';
import 'package:bakid/features/guru/jurnal/jurnal_form.dart';
import 'package:bakid/features/guru/jurnal/jurnal_providers.dart';

class JurnalPage extends ConsumerStatefulWidget {
  const JurnalPage({super.key});

  @override
  ConsumerState<JurnalPage> createState() => _JurnalPageState();
}

class _JurnalPageState extends ConsumerState<JurnalPage>
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
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Jurnal Mengajar',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(100),
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(icon: Icon(Icons.fingerprint)),
            Tab(icon: Icon(Icons.history_rounded)),
          ],
        ),
      ),
      floatingActionButton:
          _tabController.index == 1
              ? FloatingActionButton(
                onPressed: () => _tabController.animateTo(0),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                child: const Icon(Iconsax.add),
              )
              : null,
      body: TabBarView(
        controller: _tabController,
        children: [const JurnalForm(), _buildJurnalHistoryTab(guruId, theme)],
      ),
    );
  }

  Widget _buildJurnalHistoryTab(String guruId, ThemeData theme) {
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
            'Buat jurnal baru di tab "Buat Jurnal"',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }
}
