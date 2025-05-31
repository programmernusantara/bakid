import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';
import 'package:bakid/fitur/guru/kehadiran_siswa/absensi_siswa_providers.dart';
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
    final theme = Theme.of(context);
    final currentDate = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Absensi Siswa'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
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
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Scrollable Header Section
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Date Header Card
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Card(
                                elevation: 0,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.calendar_today,
                                          color: Colors.blue[600],
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hari Ini',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            DateFormat(
                                              'EEEE, dd MMMM yyyy',
                                              'id_ID',
                                            ).format(currentDate),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Schedule Selection
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PILIH JADWAL',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...data.map((j) {
                                    final isSelected =
                                        ref.watch(
                                          absensiSiswaSelectedJadwalProvider,
                                        )?['id'] ==
                                        j['id'];
                                    final kelas =
                                        j['kelas'] as Map<String, dynamic>?;
                                    final mapel =
                                        j['mata_pelajaran']
                                            as Map<String, dynamic>?;

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 0,
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color:
                                              isSelected
                                                  ? Theme.of(
                                                    context,
                                                  ).primaryColor
                                                  : Colors.grey.shade300,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          ref
                                              .read(
                                                absensiSiswaSelectedJadwalProvider
                                                    .notifier,
                                              )
                                              .state = j;
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isSelected
                                                          ? Theme.of(context)
                                                              .primaryColor
                                                              .withAlpha(100)
                                                          : Colors.grey[100],
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.schedule_outlined,
                                                  color:
                                                      isSelected
                                                          ? Theme.of(
                                                            context,
                                                          ).primaryColor
                                                          : Colors.grey[600],
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${mapel?['nama'] ?? 'Mata Pelajaran'}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14,
                                                        color:
                                                            isSelected
                                                                ? Theme.of(
                                                                  context,
                                                                ).primaryColor
                                                                : Colors.black,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Kelas ${kelas?['nama'] ?? ''} • ${j['waktu_mulai']} - ${j['waktu_selesai']}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                Icon(
                                                  Icons.check_circle,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                  size: 20,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),

                            // Form Section
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    // Hadir Section
                                    _buildSectionTitle(
                                      'Kehadiran Siswa',
                                      theme,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildAttendanceCard(
                                      icon: Icons.check_circle_rounded,
                                      iconColor: Colors.green,
                                      title: 'Hadir',
                                      controller: _jumlahHadirController,
                                      label: 'Jumlah siswa hadir',
                                      max:
                                          ref.watch(
                                            absensiSiswaSelectedJadwalProvider,
                                          )?['kelas']?['jumlah_murid'],
                                    ),
                                    const SizedBox(height: 12),

                                    // Izin Section
                                    _buildAttendanceCard(
                                      icon: Icons.person_outline_rounded,
                                      iconColor: Colors.orange,
                                      title: 'Izin',
                                      controller: _jumlahIzinController,
                                      label: 'Jumlah siswa izin',
                                      max:
                                          ref.watch(
                                            absensiSiswaSelectedJadwalProvider,
                                          )?['kelas']?['jumlah_murid'],
                                      additionalField: _buildNameField(
                                        controller: _namaIzinController,
                                        label: 'Nama siswa izin',
                                        hint:
                                            'Opsional (contoh: Andi, Budi, Caca)',
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Alpa Section
                                    _buildAttendanceCard(
                                      icon: Icons.person_off_rounded,
                                      iconColor: Colors.red,
                                      title: 'Alpa',
                                      controller: _jumlahAlpaController,
                                      label: 'Jumlah siswa alpa',
                                      max:
                                          ref.watch(
                                            absensiSiswaSelectedJadwalProvider,
                                          )?['kelas']?['jumlah_murid'],
                                      additionalField: _buildNameField(
                                        controller: _namaAlpaController,
                                        label: 'Nama siswa alpa',
                                        hint:
                                            'Opsional (Contoh: Dedi, Eka, Fani)',
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Submit Button
                                    _buildSubmitButton(
                                      ref.watch(
                                        absensiSiswaSelectedJadwalProvider,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Status messages at the bottom
                    if (_errorMessage.isNotEmpty || _successMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child:
                            _errorMessage.isNotEmpty
                                ? _buildStatusMessage(
                                  _errorMessage,
                                  Icons.error_outline_rounded,
                                  Colors.red,
                                )
                                : _buildStatusMessage(
                                  _successMessage,
                                  Icons.check_circle_outline_rounded,
                                  Colors.green,
                                ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusMessage(String message, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withAlpha(30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withAlpha(100)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.grey[700],
        ),
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
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(100),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
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
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        suffixText: 'siswa',
        suffixStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      style: const TextStyle(fontSize: 14),
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
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      style: const TextStyle(fontSize: 14),
      maxLines: 2,
    );
  }

  Widget _buildSubmitButton(Map<String, dynamic>? selectedJadwal) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _submitAbsensi(selectedJadwal),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child:
            _isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Text(
                  'SIMPAN ABSENSI ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
      ),
    );
  }
}
