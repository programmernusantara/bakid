import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';
import 'package:bakid/fitur/guru/jurnal/jurnal_providers.dart';

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

  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.jurnalToEdit != null) {
      _materiController.text =
          widget.jurnalToEdit!['materi_yang_dipelajari'] ?? '';
      _kendalaController.text = widget.jurnalToEdit!['kendala'] ?? '';
      _solusiController.text = widget.jurnalToEdit!['solusi'] ?? '';
    }
  }

  @override
  void dispose() {
    _materiController.dispose();
    _kendalaController.dispose();
    _solusiController.dispose();
    super.dispose();
  }

  Future<void> _submitJurnal(Map<String, dynamic>? selectedJadwal) async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedJadwal == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null || user['profil'] == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final supabase = ref.read(supabaseProvider);
      final currentDate = DateTime.now();

      // Cek apakah jurnal sudah ada untuk jadwal ini hari ini
      final existing =
          await supabase
              .from('jurnal_mengajar')
              .select()
              .eq('jadwal_id', selectedJadwal['id'])
              .eq('tanggal', DateFormat('yyyy-MM-dd').format(currentDate))
              .maybeSingle();

      if (existing != null &&
          (widget.jurnalToEdit == null ||
              existing['id'] != widget.jurnalToEdit!['id'])) {
        throw 'Anda sudah membuat jurnal untuk kelas ini hari ini';
      }

      if (widget.jurnalToEdit == null) {
        // Buat jurnal baru
        await supabase.from('jurnal_mengajar').insert({
          'guru_id': user['profil']['id'],
          'jadwal_id': selectedJadwal['id'],
          'kelas_id': selectedJadwal['kelas_id'],
          'tanggal': DateFormat('yyyy-MM-dd').format(currentDate),
          'materi_yang_dipelajari': _materiController.text,
          'kendala': _kendalaController.text,
          'solusi': _solusiController.text,
        });
        setState(() => _successMessage = 'Jurnal berhasil disimpan');
      } else {
        // Update jurnal yang sudah ada
        await supabase
            .from('jurnal_mengajar')
            .update({
              'materi_yang_dipelajari': _materiController.text,
              'kendala': _kendalaController.text,
              'solusi': _solusiController.text,
              'diperbarui_pada': DateTime.now().toIso8601String(),
            })
            .eq('id', widget.jurnalToEdit!['id']);
        setState(() => _successMessage = 'Jurnal berhasil diperbarui');
      }

      // Reset form jika membuat baru
      if (widget.jurnalToEdit == null) {
        _formKey.currentState?.reset();
        _materiController.clear();
        _kendalaController.clear();
        _solusiController.clear();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);
    final currentDate = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.jurnalToEdit == null ? 'Buat Jurnal' : 'Edit Jurnal',
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer(
          builder: (context, ref, _) {
            final jadwal = ref.watch(jurnalJadwalProvider);

            return jadwal.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada jadwal mengajar hari ini',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _buildHeaderSection(currentDate),
                      const SizedBox(height: 24),

                      // Status messages
                      if (_errorMessage.isNotEmpty)
                        _buildStatusMessage(
                          _errorMessage,
                          Icons.error_outline_rounded,
                          Colors.red,
                        ),
                      if (_successMessage.isNotEmpty)
                        _buildStatusMessage(
                          _successMessage,
                          Icons.check_circle_outline_rounded,
                          Colors.green,
                        ),
                      const SizedBox(height: 16),

                      // Schedule Dropdown
                      _buildJadwalDropdown(data),
                      const SizedBox(height: 24),

                      // Form Section
                      Consumer(
                        builder: (context, ref, _) {
                          final selectedJadwal = ref.watch(
                            jurnalSelectedJadwalProvider,
                          );
                          return Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Materi Section
                                _buildSectionTitle('Materi yang Diajarkan'),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  controller: _materiController,
                                  label: 'Materi yang diajarkan',
                                  hint: 'Masukkan materi yang diajarkan',
                                  maxLines: 4,
                                  isRequired: true,
                                ),
                                const SizedBox(height: 16),

                                // Kendala Section
                                _buildSectionTitle('Kendala'),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  controller: _kendalaController,
                                  label: 'Kendala yang dihadapi',
                                  hint: 'Masukkan kendala yang dihadapi',
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 16),

                                // Solusi Section
                                _buildSectionTitle('Solusi'),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  controller: _solusiController,
                                  label: 'Solusi yang dilakukan',
                                  hint: 'Masukkan solusi yang dilakukan',
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 32),

                                // Submit Button
                                _buildSubmitButton(selectedJadwal),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderSection(DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hari Ini',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessage(String message, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildJadwalDropdown(List<Map<String, dynamic>> jadwalList) {
    return Consumer(
      builder: (context, ref, _) {
        final selectedJadwal = ref.watch(jurnalSelectedJadwalProvider);
        final selected = selectedJadwal ?? jadwalList.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Jadwal Mengajar'),
            const SizedBox(height: 8),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: selected,
              decoration: InputDecoration(
                labelText: 'Pilih Jadwal',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              items:
                  jadwalList.map((jadwal) {
                    final mp = jadwal['mata_pelajaran'] ?? {};
                    final kelas = jadwal['kelas'] ?? {};
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: jadwal,
                      child: Text(
                        '${mp['nama']} - ${kelas['nama']} (${jadwal['waktu_mulai']}-${jadwal['waktu_selesai']})',
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(jurnalSelectedJadwalProvider.notifier).state = value;
                }
              },
              validator: (value) {
                if (value == null) return 'Pilih jadwal terlebih dahulu';
                return null;
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(16),
      ),
      maxLines: maxLines,
      validator:
          isRequired
              ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Field ini wajib diisi';
                }
                return null;
              }
              : null,
    );
  }

  Widget _buildSubmitButton(Map<String, dynamic>? selectedJadwal) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _submitJurnal(selectedJadwal),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.jurnalToEdit == null
                          ? Icons.save_rounded
                          : Icons.edit_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.jurnalToEdit == null
                          ? 'Simpan Jurnal'
                          : 'Update Jurnal',
                    ),
                  ],
                ),
      ),
    );
  }
}
