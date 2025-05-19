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

  Future<void> _submitAbsensi(Map<String, dynamic>? selectedJadwal) async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedJadwal == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null || user['profil'] == null) return;

    // Validasi jumlah siswa
    final kelas = selectedJadwal['kelas'] as Map<String, dynamic>?;
    final jumlahSiswa = kelas?['jumlah_murid'] as int? ?? 0;
    final totalAbsen =
        (int.tryParse(_jumlahHadirController.text) ?? 0) +
        (int.tryParse(_jumlahIzinController.text) ?? 0) +
        (int.tryParse(_jumlahAlpaController.text) ?? 0);

    if (jumlahSiswa > 0 && totalAbsen != jumlahSiswa) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Total absen ($totalAbsen) harus sama dengan jumlah siswa ($jumlahSiswa)',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = ref.read(supabaseProvider);
      final selectedDate = ref.read(absensiSiswaDateProvider);

      // Cek duplikasi absensi
      final existing =
          await supabase
              .from('rekap_absensi_siswa')
              .select()
              .eq('jadwal_id', selectedJadwal['id'])
              .eq('tanggal', DateFormat('yyyy-MM-dd').format(selectedDate))
              .maybeSingle();

      if (existing != null) {
        throw 'Anda sudah mengisi absensi untuk kelas ini hari ini';
      }

      // Simpan absensi
      await supabase.from('rekap_absensi_siswa').insert({
        'guru_id': user['profil']['id'],
        'jadwal_id': selectedJadwal['id'],
        'kelas_id': selectedJadwal['kelas_id'],
        'tanggal': DateFormat('yyyy-MM-dd').format(selectedDate),
        'jumlah_hadir': int.tryParse(_jumlahHadirController.text) ?? 0,
        'jumlah_izin': int.tryParse(_jumlahIzinController.text) ?? 0,
        'jumlah_alpa': int.tryParse(_jumlahAlpaController.text) ?? 0,
        'nama_izin': _namaIzinController.text.trim(),
        'nama_alpa': _namaAlpaController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absensi berhasil disimpan')),
      );

      // Reset form
      _formKey.currentState?.reset();
      _jumlahHadirController.clear();
      _jumlahIzinController.clear();
      _namaIzinController.clear();
      _jumlahAlpaController.clear();
      _namaAlpaController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final selectedDate = ref.read(absensiSiswaDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      ref.read(absensiSiswaDateProvider.notifier).state = picked;
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
    final selectedDate = ref.watch(absensiSiswaDateProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Tanggal dan Jadwal
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat(
                    'EEEE, dd MMMM yyyy',
                    'id_ID',
                  ).format(selectedDate),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dropdown Jadwal
          const JadwalAbsensiDropdown(),

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
                    _buildNumberField(
                      controller: _jumlahHadirController,
                      label: 'Jumlah Hadir',
                      max: selectedJadwal?['kelas']?['jumlah_murid'],
                    ),
                    const SizedBox(height: 16),

                    _buildNumberField(
                      controller: _jumlahIzinController,
                      label: 'Jumlah Izin',
                      max: selectedJadwal?['kelas']?['jumlah_murid'],
                    ),
                    _buildNameField(
                      controller: _namaIzinController,
                      label: 'Nama Siswa Izin',
                      hint: 'Pisahkan dengan koma',
                    ),
                    const SizedBox(height: 16),

                    _buildNumberField(
                      controller: _jumlahAlpaController,
                      label: 'Jumlah Alpa',
                      max: selectedJadwal?['kelas']?['jumlah_murid'],
                    ),
                    _buildNameField(
                      controller: _namaAlpaController,
                      label: 'Nama Siswa Alpa',
                      hint: 'Pisahkan dengan koma',
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () => _submitAbsensi(selectedJadwal),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator()
                                : const Text('SIMPAN ABSENSI'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
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
        border: const OutlineInputBorder(),
        suffixText: 'siswa',
      ),
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
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          hintText: hint,
        ),
        maxLines: 2,
      ),
    );
  }
}
