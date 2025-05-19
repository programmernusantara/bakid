import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/features/auth/auth_providers.dart';
import 'package:bakid/features/guru/jurnal/jurnal_providers.dart';

class JurnalForm extends ConsumerStatefulWidget {
  final Map<String, dynamic>? jurnalToEdit;

  const JurnalForm({super.key, this.jurnalToEdit});

  @override
  ConsumerState<JurnalForm> createState() => _JurnalFormState();
}

class _JurnalFormState extends ConsumerState<JurnalForm> {
  final _formKey = GlobalKey<FormState>();
  final _materiController = TextEditingController();
  final _kendalaController = TextEditingController();
  final _solusiController = TextEditingController();

  Map<String, dynamic>? _selectedJadwal;
  bool _isLoading = false;
  bool _isJurnalExist = false;

  @override
  void initState() {
    super.initState();
    if (widget.jurnalToEdit != null) {
      _materiController.text =
          widget.jurnalToEdit!['materi_yang_dipelajari'] ?? '';
      _kendalaController.text = widget.jurnalToEdit!['kendala'] ?? '';
      _solusiController.text = widget.jurnalToEdit!['solusi'] ?? '';
      _selectedJadwal = widget.jurnalToEdit!['jadwal_mengajar'];
    }
  }

  @override
  void dispose() {
    _materiController.dispose();
    _kendalaController.dispose();
    _solusiController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingJurnal() async {
    if (_selectedJadwal == null) return;

    final user = ref.read(currentUserProvider);
    final guruId = user?['profil']?['id'];
    final today = DateTime.now().toIso8601String().split('T')[0];

    final existingJurnal = await ref.read(
      jurnalHariIniByJadwalProvider({
        'guruId': guruId,
        'jadwalId': _selectedJadwal!['id'],
        'tanggal': today,
      }).future,
    );

    setState(() {
      _isJurnalExist =
          existingJurnal != null &&
          (widget.jurnalToEdit == null ||
              existingJurnal['id'] != widget.jurnalToEdit!['id']);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedJadwal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jadwal mengajar terlebih dahulu')),
      );
      return;
    }

    if (_isJurnalExist) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sudah ada jurnal untuk jadwal ini hari ini'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = ref.read(currentUserProvider);
    final guruId = user?['profil']?['id'];
    final supabase = ref.read(supabaseProvider);
    final today = DateTime.now().toIso8601String().split('T')[0];

    try {
      if (widget.jurnalToEdit == null) {
        await supabase.from('jurnal_mengajar').insert({
          'guru_id': guruId,
          'jadwal_id': _selectedJadwal!['id'],
          'tanggal': today,
          'materi_yang_dipelajari': _materiController.text,
          'kendala': _kendalaController.text,
          'solusi': _solusiController.text,
        });
      } else {
        await supabase
            .from('jurnal_mengajar')
            .update({
              'materi_yang_dipelajari': _materiController.text,
              'kendala': _kendalaController.text,
              'solusi': _solusiController.text,
              'diperbarui_pada': DateTime.now().toIso8601String(),
            })
            .eq('id', widget.jurnalToEdit!['id']);
      }

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(jurnalProvider(guruId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final guruId = user?['profil']?['id'] as String?;
    final today = DateTime.now();
    final currentDay = today.weekday;

    if (guruId == null) {
      return const Scaffold(
        body: Center(child: Text('Guru ID tidak ditemukan')),
      );
    }

    final jadwalAsync = ref.watch(jadwalGuruProvider(guruId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.jurnalToEdit == null ? 'Buat Jurnal Baru' : 'Edit Jurnal',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: jadwalAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (jadwalList) {
            final jadwalHariIni =
                jadwalList
                    .where(
                      (jadwal) => jadwal['hari_dalam_minggu'] == currentDay,
                    )
                    .toList();

            if (jadwalHariIni.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.schedule, size: 48),
                    const SizedBox(height: 16),
                    const Text('Tidak ada jadwal mengajar hari ini'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kembali'),
                    ),
                  ],
                ),
              );
            }

            // Pastikan _selectedJadwal valid
            if (_selectedJadwal == null ||
                !jadwalHariIni.any((j) => j['id'] == _selectedJadwal!['id'])) {
              _selectedJadwal = jadwalHariIni.first;
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkExistingJurnal();
            });

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informasi Tanggal
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.blue),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('EEEE, d MMMM y', 'id').format(today),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pilih Jadwal
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Jadwal Mengajar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            value: _selectedJadwal,
                            decoration: InputDecoration(
                              labelText: 'Pilih Jadwal',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items:
                                jadwalHariIni.map((jadwal) {
                                  final mp = jadwal['mata_pelajaran'] ?? {};
                                  final kelas = jadwal['kelas'] ?? {};
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: jadwal,
                                    key: ValueKey(jadwal['id']),
                                    child: Text(
                                      '${mp['nama']} - ${kelas['nama']} (${jadwal['waktu_mulai']}-${jadwal['waktu_selesai']})',
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedJadwal = value;
                                  _checkExistingJurnal();
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Pilih jadwal terlebih dahulu';
                              }
                              return null;
                            },
                          ),
                          if (_isJurnalExist)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning,
                                    color: Colors.orange[800],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sudah ada jurnal untuk jadwal ini hari ini',
                                    style: TextStyle(color: Colors.orange[800]),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form Input
                  _buildSection(
                    title: 'Materi yang Diajarkan',
                    icon: Icons.book,
                    child: TextFormField(
                      controller: _materiController,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan materi yang diajarkan',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Materi tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    title: 'Kendala',
                    icon: Icons.warning_amber,
                    child: TextFormField(
                      controller: _kendalaController,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan kendala yang dihadapi (opsional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    title: 'Solusi',
                    icon: Icons.lightbulb,
                    child: TextFormField(
                      controller: _solusiController,
                      decoration: const InputDecoration(
                        hintText: 'Masukkan solusi yang dilakukan (opsional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'SIMPAN JURNAL',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
