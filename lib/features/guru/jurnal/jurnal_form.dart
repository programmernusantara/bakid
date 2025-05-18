import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/features/auth/auth_providers.dart';
import 'package:bakid/features/guru/jurnal/jurnal_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
      _isJurnalExist = existingJurnal != null && widget.jurnalToEdit == null;
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.jurnalToEdit == null ? 'Buat Jurnal' : 'Edit Jurnal',
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Tanggal dan Jadwal
                    Card(
                      color: Colors.white,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, d MMMM y', 'id').format(today),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            jadwalAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (error, stack) => Text('Error: $error'),
                              data: (jadwalList) {
                                final jadwalHariIni =
                                    jadwalList
                                        .where(
                                          (jadwal) =>
                                              jadwal['hari_dalam_minggu'] ==
                                              currentDay,
                                        )
                                        .toList();

                                if (jadwalHariIni.isEmpty) {
                                  return const Text(
                                    'Tidak ada jadwal mengajar hari ini',
                                    style: TextStyle(color: Colors.red),
                                  );
                                }

                                _selectedJadwal ??= jadwalHariIni.first;
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  _checkExistingJurnal();
                                });

                                return Column(
                                  children: [
                                    DropdownButtonFormField<
                                      Map<String, dynamic>
                                    >(
                                      value: _selectedJadwal,
                                      decoration: InputDecoration(
                                        labelText: 'Pilih Jadwal',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                      ),
                                      items:
                                          jadwalHariIni.map((jadwal) {
                                            final mp =
                                                jadwal['mata_pelajaran'] ?? {};
                                            final kelas = jadwal['kelas'] ?? {};
                                            return DropdownMenuItem(
                                              value: jadwal,
                                              child: Text(
                                                '${mp['nama']} - ${kelas['nama']} (${jadwal['waktu_mulai']}-${jadwal['waktu_selesai']})',
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedJadwal = value;
                                          _checkExistingJurnal();
                                        });
                                      },
                                    ),
                                    if (_isJurnalExist)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Text(
                                          '⚠️ Sudah ada jurnal untuk jadwal ini hari ini',
                                          style: TextStyle(
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Input
                    _buildTextField(
                      controller: _materiController,
                      label: 'Materi yang Diajarkan*',
                      hint: 'Masukkan materi yang diajarkan',
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Materi tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _kendalaController,
                      label: 'Kendala',
                      hint: 'Masukkan kendala yang dihadapi (opsional)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _solusiController,
                      label: 'Solusi',
                      hint: 'Masukkan solusi yang dilakukan (opsional)',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _formKey.currentState?.validate() == true
                            ? Colors.blue
                            : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'SIMPAN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: maxLines,
          validator: validator,
        ),
      ],
    );
  }
}
