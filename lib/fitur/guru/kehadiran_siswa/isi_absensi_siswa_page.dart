import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/fitur/guru/kehadiran_siswa/absensi_siswa_providers.dart';
import 'package:bakid/fitur/guru/kehadiran_siswa/jadwal_absensi_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';

class IsiAbsensiSiswaPage extends ConsumerStatefulWidget {
  const IsiAbsensiSiswaPage({super.key});

  @override
  ConsumerState<IsiAbsensiSiswaPage> createState() =>
      _IsiAbsensiSiswaPageState();
}

class _IsiAbsensiSiswaPageState extends ConsumerState<IsiAbsensiSiswaPage> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahHadirController = TextEditingController();
  final _jumlahIzinController = TextEditingController();
  final _namaIzinController = TextEditingController();
  final _jumlahAlpaController = TextEditingController();
  final _namaAlpaController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  Future<void> _submitAbsensi(Map<String, dynamic>? selectedJadwal) async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedJadwal == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null || user['profil'] == null) return;

    final kelas = selectedJadwal['kelas'] as Map<String, dynamic>?;
    final jumlahSiswa = kelas?['jumlah_murid'] as int? ?? 0;
    final totalAbsen =
        (int.tryParse(_jumlahHadirController.text) ?? 0) +
        (int.tryParse(_jumlahIzinController.text) ?? 0) +
        (int.tryParse(_jumlahAlpaController.text) ?? 0);

    if (jumlahSiswa > 0 && totalAbsen != jumlahSiswa) {
      setState(() {
        _errorMessage =
            'Total absen ($totalAbsen) harus sama dengan jumlah siswa ($jumlahSiswa)';
        _successMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final supabase = ref.read(supabaseProvider);
      final currentDate = DateTime.now();

      final existing =
          await supabase
              .from('rekap_absensi_siswa')
              .select()
              .eq('jadwal_id', selectedJadwal['id'])
              .eq('tanggal', DateFormat('yyyy-MM-dd').format(currentDate))
              .maybeSingle();

      if (existing != null) {
        throw 'Anda sudah mengisi absensi untuk kelas ini hari ini';
      }

      await supabase.from('rekap_absensi_siswa').insert({
        'guru_id': user['profil']['id'],
        'jadwal_id': selectedJadwal['id'],
        'kelas_id': selectedJadwal['kelas_id'],
        'tanggal': DateFormat('yyyy-MM-dd').format(currentDate),
        'jumlah_hadir': int.tryParse(_jumlahHadirController.text) ?? 0,
        'jumlah_izin': int.tryParse(_jumlahIzinController.text) ?? 0,
        'jumlah_alpa': int.tryParse(_jumlahAlpaController.text) ?? 0,
        'nama_izin': _namaIzinController.text.trim(),
        'nama_alpa': _namaAlpaController.text.trim(),
      });

      setState(() {
        _successMessage = 'Absensi berhasil disimpan';
        _formKey.currentState?.reset();
        _jumlahHadirController.clear();
        _jumlahIzinController.clear();
        _namaIzinController.clear();
        _jumlahAlpaController.clear();
        _namaAlpaController.clear();
      });
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _jumlahHadirController.dispose();
    _jumlahIzinController.dispose();
    _namaIzinController.dispose();
    _jumlahAlpaController.dispose();
    _namaAlpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentDate = DateTime.now();
    Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Isi Absensi Siswa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              _buildDateHeader(currentDate),
              const SizedBox(height: 24),

              // Status messages
              if (_errorMessage.isNotEmpty)
                _buildStatusCard(
                  _errorMessage,
                  Colors.red[50]!,
                  Colors.red[700]!,
                ),

              if (_successMessage.isNotEmpty)
                _buildStatusCard(
                  _successMessage,
                  Colors.green[50]!,
                  Colors.green[700]!,
                ),

              const SizedBox(height: 8),
              const JadwalAbsensiDropdown(),
              const SizedBox(height: 16),

              // Form Section
              Consumer(
                builder: (context, ref, _) {
                  final selectedJadwal = ref.watch(
                    absensiSiswaSelectedJadwalProvider,
                  );
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header
                        const Text(
                          'Data Absensi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Hadir Section
                        _buildInputCard(
                          title: 'Hadir',
                          icon: Icons.check_circle_outline,
                          iconColor: Colors.green,
                          children: [
                            _buildModernNumberField(
                              controller: _jumlahHadirController,
                              label: 'Jumlah Siswa Hadir',
                              max: selectedJadwal?['kelas']?['jumlah_murid'],
                              icon: Icons.people_alt_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Izin Section
                        _buildInputCard(
                          title: 'Izin',
                          icon: Icons.help_outline,
                          iconColor: Colors.blue,
                          children: [
                            _buildModernNumberField(
                              controller: _jumlahIzinController,
                              label: 'Jumlah Siswa Izin',
                              max: selectedJadwal?['kelas']?['jumlah_murid'],
                              icon: Icons.people_alt_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildModernTextField(
                              controller: _namaIzinController,
                              label: 'Nama Siswa Izin',
                              hint: 'Pisahkan dengan koma',
                              icon: Icons.list_alt_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Alpa Section
                        _buildInputCard(
                          title: 'Alpa',
                          icon: Icons.highlight_off_outlined,
                          iconColor: Colors.red,
                          children: [
                            _buildModernNumberField(
                              controller: _jumlahAlpaController,
                              label: 'Jumlah Siswa Alpa',
                              max: selectedJadwal?['kelas']?['jumlah_murid'],
                              icon: Icons.people_alt_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildModernTextField(
                              controller: _namaAlpaController,
                              label: 'Nama Siswa Alpa',
                              hint: 'Pisahkan dengan koma',
                              icon: Icons.list_alt_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () => _submitAbsensi(selectedJadwal),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                                    : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save_alt_outlined, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'SIMPAN ABSENSI',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (keep all the existing helper methods unchanged)
  // _buildDateHeader, _buildStatusCard, _buildInputCard,
  // _buildModernNumberField, _buildModernTextField
}

Widget _buildDateHeader(DateTime date) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Hari Ini', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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

Widget _buildStatusCard(String message, Color bgColor, Color textColor) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: textColor.withAlpha(100)),
    ),
    child: Row(
      children: [
        Icon(
          textColor == Colors.red[700]
              ? Icons.error_outline
              : Icons.check_circle_outline,
          color: textColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildInputCard({
  required String title,
  required List<Widget> children,
  required IconData icon,
  required Color iconColor,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    ],
  );
}

Widget _buildModernNumberField({
  required TextEditingController controller,
  required String label,
  int? max,
  required IconData icon,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
      suffixText: 'siswa',
      suffixStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
    ),
    style: const TextStyle(color: Colors.black87, fontSize: 14),
    keyboardType: TextInputType.number,
    validator: (value) {
      if (value == null || value.isEmpty) return 'Harus diisi';
      final num = int.tryParse(value);
      if (num == null) return 'Harus angka';
      if (max != null && num > max) return 'Maksimal $max';
      return null;
    },
  );
}

Widget _buildModernTextField({
  required TextEditingController controller,
  required String label,
  String? hint,
  required IconData icon,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
    ),
    style: const TextStyle(color: Colors.black87, fontSize: 14),
    maxLines: 2,
  );
}
