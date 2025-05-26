import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';
import 'package:bakid/fitur/guru/kehadiran_siswa/absensi_siswa_providers.dart';
import 'package:bakid/fitur/guru/kehadiran_siswa/jadwal_absensi_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

  @override
  void dispose() {
    _jumlahHadirController.dispose();
    _jumlahIzinController.dispose();
    _namaIzinController.dispose();
    _jumlahAlpaController.dispose();
    _namaAlpaController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    Theme.of(context);
    final currentDate = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Isi Absensi Siswa'),
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
            final jadwal = ref.watch(absensiSiswaJadwalProvider);

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
                      const JadwalAbsensiDropdown(),
                      const SizedBox(height: 24),

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
                                // Hadir Section
                                _buildSectionTitle('Kehadiran Siswa'),
                                const SizedBox(height: 16),
                                _buildAttendanceCard(
                                  icon: Icons.check_circle_rounded,
                                  iconColor: Colors.green,
                                  title: 'Hadir',
                                  controller: _jumlahHadirController,
                                  label: 'Jumlah siswa hadir',
                                  max:
                                      selectedJadwal?['kelas']?['jumlah_murid'],
                                ),
                                const SizedBox(height: 16),

                                // Izin Section
                                _buildAttendanceCard(
                                  icon: Icons.person_outline_rounded,
                                  iconColor: Colors.orange,
                                  title: 'Izin',
                                  controller: _jumlahIzinController,
                                  label: 'Jumlah siswa izin',
                                  max:
                                      selectedJadwal?['kelas']?['jumlah_murid'],
                                  additionalField: _buildNameField(
                                    controller: _namaIzinController,
                                    label: 'Nama siswa izin',
                                    hint: 'Opsional (contoh: Andi, Budi, Caca)',
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Alpa Section
                                _buildAttendanceCard(
                                  icon: Icons.person_off_rounded,
                                  iconColor: Colors.red,
                                  title: 'Alpa',
                                  controller: _jumlahAlpaController,
                                  label: 'Jumlah siswa alpa',
                                  max:
                                      selectedJadwal?['kelas']?['jumlah_murid'],
                                  additionalField: _buildNameField(
                                    controller: _namaAlpaController,
                                    label: 'Nama siswa alpa',
                                    hint: 'Opsional (Contoh: Dedi, Eka, Fani)',
                                  ),
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

  Widget _buildAttendanceCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required TextEditingController controller,
    required String label,
    int? max,
    Widget? additionalField,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(100),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNumberInput(controller: controller, label: label, max: max),
            if (additionalField != null) ...[
              const SizedBox(height: 12),
              additionalField,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput({
    required TextEditingController controller,
    required String label,
    int? max,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixText: 'siswa',
        suffixStyle: TextStyle(color: Colors.grey[600]),
      ),
      style: const TextStyle(color: Colors.black87),
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
        labelStyle: TextStyle(color: Colors.grey[600]),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: const TextStyle(color: Colors.black87),
      maxLines: 2,
    );
  }

  Widget _buildSubmitButton(Map<String, dynamic>? selectedJadwal) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _submitAbsensi(selectedJadwal),
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
                : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Simpan Absensi'),
                  ],
                ),
      ),
    );
  }
}
