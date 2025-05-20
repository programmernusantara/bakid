import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/features/guru/kehadiran/absensi_siswa_providers.dart';
import 'package:bakid/features/guru/kehadiran/jadwal_absensi_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bakid/features/auth/auth_providers.dart';

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
      setState(
        () =>
            _errorMessage =
                'Total absen ($totalAbsen) harus sama dengan jumlah siswa ($jumlahSiswa)',
      );
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

      setState(() => _successMessage = 'Absensi berhasil disimpan');
      _formKey.currentState?.reset();
      _jumlahHadirController.clear();
      _jumlahIzinController.clear();
      _namaIzinController.clear();
      _jumlahAlpaController.clear();
      _namaAlpaController.clear();
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

    return Scaffold(
      backgroundColor: Colors.grey[200], // Soft gray background

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
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

            // Date Card
            _buildDateCard(currentDate),

            const SizedBox(height: 20),

            // Jadwal Dropdown
            const JadwalAbsensiDropdown(),

            const SizedBox(height: 24),

            // Form Absensi
            Consumer(
              builder: (context, ref, _) {
                final selectedJadwal = ref.watch(
                  absensiSiswaSelectedJadwalProvider,
                );
                return Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildInputSection(
                        title: 'Kehadiran',
                        children: [
                          _buildNumberField(
                            controller: _jumlahHadirController,
                            label: 'Jumlah Hadir',
                            max: selectedJadwal?['kelas']?['jumlah_murid'],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildInputSection(
                        title: 'Izin',
                        children: [
                          _buildNumberField(
                            controller: _jumlahIzinController,
                            label: 'Jumlah Izin',
                            max: selectedJadwal?['kelas']?['jumlah_murid'],
                          ),
                          const SizedBox(height: 12),
                          _buildNameField(
                            controller: _namaIzinController,
                            label: 'Nama Siswa Izin',
                            hint: 'Pisahkan dengan koma',
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildInputSection(
                        title: 'Alpa',
                        children: [
                          _buildNumberField(
                            controller: _jumlahAlpaController,
                            label: 'Jumlah Alpa',
                            max: selectedJadwal?['kelas']?['jumlah_murid'],
                          ),
                          const SizedBox(height: 12),
                          _buildNameField(
                            controller: _namaAlpaController,
                            label: 'Nama Siswa Alpa',
                            hint: 'Pisahkan dengan koma',
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

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
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                                  : const Text(
                                    'SIMPAN ABSENSI',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
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
    );
  }

  Widget _buildStatusCard(String message, Color bgColor, Color textColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDateCard(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100], // Soft gray card background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100], // Soft gray card background
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    int? max,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        filled: true,
        fillColor: Colors.white, // White input background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixText: 'siswa',
        suffixStyle: const TextStyle(color: Colors.grey, fontSize: 14),
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

  Widget _buildNameField({
    required TextEditingController controller,
    required String label,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: Colors.white, // White input background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      maxLines: 2,
    );
  }
}
