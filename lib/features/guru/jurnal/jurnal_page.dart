import 'package:bakid/features/auth/auth_providers.dart';
import 'package:bakid/features/guru/jurnal/components/jurnal_card.dart';
import 'package:bakid/features/guru/jurnal/jurnal_form.dart';
import 'package:bakid/features/guru/jurnal/jurnal_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JurnalPage extends ConsumerStatefulWidget {
  const JurnalPage({super.key});

  @override
  ConsumerState<JurnalPage> createState() => _JurnalPageState();
}

class _JurnalPageState extends ConsumerState<JurnalPage> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final guruId = user?['profil']?['id'] as String?;

    if (guruId == null) {
      return const Center(child: Text('Guru ID tidak ditemukan'));
    }

    final jurnalAsync = ref.watch(jurnalProvider(guruId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed:
                () => showSearch(
                  context: context,
                  delegate: JurnalSearchDelegate(ref, guruId),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const JurnalForm()),
            ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(jurnalProvider(guruId).future),
        child: _buildJurnalList(jurnalAsync),
      ),
    );
  }

  Widget _buildJurnalList(AsyncValue<List<Map<String, dynamic>>> jurnalAsync) {
    return jurnalAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (jurnalList) {
        if (jurnalList.isEmpty) {
          return _buildEmptyState();
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jurnalList.length,
          itemBuilder: (context, index) {
            final jurnal = jurnalList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: JurnalCard(
                jurnal: jurnal,
                onEdit:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JurnalForm(jurnalToEdit: jurnal),
                      ),
                    ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Belum ada jurnal yang dibuat',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class JurnalSearchDelegate extends SearchDelegate {
  final WidgetRef ref;
  final String guruId;

  JurnalSearchDelegate(this.ref, this.guruId);

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final jurnalAsync = ref.watch(jurnalProvider(guruId));

    return jurnalAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (jurnalList) {
        final filteredList =
            jurnalList.where((jurnal) {
              final jadwal = jurnal['jadwal_mengajar'] ?? {};
              final mp = jadwal['mata_pelajaran'] ?? {};
              final kelas = jadwal['kelas'] ?? {};

              return jurnal['materi_yang_dipelajari']?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ==
                      true ||
                  jurnal['kendala']?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ==
                      true ||
                  jurnal['solusi']?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ==
                      true ||
                  mp['nama']?.toLowerCase().contains(query.toLowerCase()) ==
                      true ||
                  kelas['nama']?.toLowerCase().contains(query.toLowerCase()) ==
                      true;
            }).toList();

        return ListView.builder(
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final jurnal = filteredList[index];
            return JurnalCard(
              jurnal: jurnal,
              onEdit: () {
                close(context, null);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JurnalForm(jurnalToEdit: jurnal),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
