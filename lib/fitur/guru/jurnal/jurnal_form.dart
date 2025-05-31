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
  final _materiAwalController = TextEditingController();
  final _materiAkhirController = TextEditingController();
  final _kendalaController = TextEditingController();
  final _solusiController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.jurnalToEdit != null) {
      final materi = widget.jurnalToEdit!['materi_yang_dipelajari'] ?? '';
      if (materi.contains('||')) {
        final parts = materi.split('||');
        _materiAwalController.text = parts[0].trim();
        _materiAkhirController.text = parts[1].trim();
      } else {
        _materiAwalController.text = materi;
      }
      _kendalaController.text = widget.jurnalToEdit!['kendala'] ?? '';
      _solusiController.text = widget.jurnalToEdit!['solusi'] ?? '';
    }
  }

  @override
  void dispose() {
    _materiAwalController.dispose();
    _materiAkhirController.dispose();
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

      final combinedMateri =
          '${_materiAwalController.text.trim()} || ${_materiAkhirController.text.trim()}';

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
        await supabase.from('jurnal_mengajar').insert({
          'guru_id': user['profil']['id'],
          'jadwal_id': selectedJadwal['id'],
          'kelas_id': selectedJadwal['kelas_id'],
          'tanggal': DateFormat('yyyy-MM-dd').format(currentDate),
          'materi_yang_dipelajari': combinedMateri,
          'kendala': _kendalaController.text,
          'solusi': _solusiController.text,
        });
        setState(() => _successMessage = 'Jurnal berhasil disimpan');
      } else {
        await supabase
            .from('jurnal_mengajar')
            .update({
              'materi_yang_dipelajari': combinedMateri,
              'kendala': _kendalaController.text,
              'solusi': _solusiController.text,
              'diperbarui_pada': DateTime.now().toIso8601String(),
            })
            .eq('id', widget.jurnalToEdit!['id']);
        setState(() => _successMessage = 'Jurnal berhasil diperbarui');
      }

      if (widget.jurnalToEdit == null) {
        _formKey.currentState?.reset();
        _materiAwalController.clear();
        _materiAkhirController.clear();
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
    final theme = Theme.of(context);
    final currentDate = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.grey[200],
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
        backgroundColor: Colors.white,
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
                    // Scrollable Content
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
                                          jurnalSelectedJadwalProvider,
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
                                                jurnalSelectedJadwalProvider
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

                                    // Materi Section
                                    _buildSectionTitle(
                                      'Materi Pembelajaran',
                                      theme,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildFormCard(
                                      icon: Icons.menu_book_rounded,
                                      iconColor: Colors.blue,
                                      title: 'Awal Materi',
                                      child: _buildInputField(
                                        controller: _materiAwalController,
                                        label:
                                            'Masukkan materi awal pembelajaran',
                                        isRequired: true,
                                        maxLines: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildFormCard(
                                      icon: Icons.menu_book_rounded,
                                      iconColor: Colors.blue,
                                      title: 'Akhir Materi',
                                      child: _buildInputField(
                                        controller: _materiAkhirController,
                                        label:
                                            'Masukkan materi akhir pembelajaran',
                                        maxLines: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Kendala Section
                                    _buildSectionTitle(
                                      'Kendala Pembelajaran',
                                      theme,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildFormCard(
                                      icon: Icons.warning_rounded,
                                      iconColor: Colors.orange,
                                      title: 'Kendala',
                                      child: _buildInputField(
                                        controller: _kendalaController,
                                        label: 'Masukkan kendala yang dihadapi',
                                        maxLines: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Solusi Section
                                    _buildSectionTitle('Solusi Kendala', theme),
                                    const SizedBox(height: 12),
                                    _buildFormCard(
                                      icon: Icons.lightbulb_rounded,
                                      iconColor: Colors.green,
                                      title: 'Solusi',
                                      child: _buildInputField(
                                        controller: _solusiController,
                                        label: 'Masukkan solusi yang dilakukan',
                                        maxLines: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Submit Button
                                    _buildSubmitButton(
                                      ref.watch(jurnalSelectedJadwalProvider),
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

  Widget _buildFormCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
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
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool isRequired = false,
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
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: const TextStyle(fontSize: 14),
      maxLines: maxLines,
      validator:
          isRequired
              ? (value) {
                if (value == null || value.isEmpty) return 'Harus diisi';
                return null;
              }
              : null,
    );
  }

  Widget _buildSubmitButton(Map<String, dynamic>? selectedJadwal) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _submitJurnal(selectedJadwal),
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
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      widget.jurnalToEdit == null
                          ? 'SIMPAN JURNAL'
                          : 'Perbarui Jurnal',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
