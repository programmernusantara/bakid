// jurnal_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
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
    if (_selectedJadwal == null || !mounted) return;

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

    if (!mounted) return;
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
      _showNotification('Pilih jadwal mengajar terlebih dahulu', isError: true);
      return;
    }

    if (_isJurnalExist) {
      _showNotification(
        'Sudah ada jurnal untuk jadwal ini hari ini',
        isError: true,
      );
      return;
    }

    if (!mounted) return;
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
        if (mounted) _showNotification('Jurnal berhasil dibuat');
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
        if (mounted) _showNotification('Jurnal berhasil diperbarui');
      }

      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      Navigator.of(context).pop();
      ref.invalidate(jurnalProvider(guruId));
    } catch (e) {
      if (mounted) {
        _showNotification('Gagal menyimpan: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNotification(String message, {bool isError = false}) {
    if (!mounted) return;

    final scaffold = ScaffoldMessenger.of(context);
    scaffold.hideCurrentSnackBar();
    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final guruId = user?['profil']?['id'] as String?;
    final today = DateTime.now();
    final currentDay = today.weekday;

    if (guruId == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Guru ID tidak ditemukan',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final jadwalAsync = ref.watch(jadwalGuruProvider(guruId));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Form(
        key: _formKey,
        child: jadwalAsync.when(
          loading:
              () => Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
          error:
              (error, stack) => Center(
                child: Text(
                  'Error: $error',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
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
                    Icon(
                      Iconsax.calendar_remove,
                      size: 48,
                      color: theme.colorScheme.onSurface.withAlpha(100),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada jadwal mengajar hari ini',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(100),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (_selectedJadwal == null ||
                !jadwalHariIni.any((j) => j['id'] == _selectedJadwal!['id'])) {
              _selectedJadwal = jadwalHariIni.first;
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _checkExistingJurnal();
              }
            });

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Date Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withAlpha(100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.calendar_1,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE, d MMMM y', 'id').format(today),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Schedule Selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadwal Mengajar',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: _selectedJadwal,
                        decoration: InputDecoration(
                          labelText: 'Pilih Jadwal',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withAlpha(100),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                        items:
                            jadwalHariIni.map((jadwal) {
                              final mp = jadwal['mata_pelajaran'] ?? {};
                              final kelas = jadwal['kelas'] ?? {};
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: jadwal,
                                key: ValueKey(jadwal['id']),
                                child: Text(
                                  '${mp['nama']} - ${kelas['nama']} (${jadwal['waktu_mulai']}-${jadwal['waktu_selesai']}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null && mounted) {
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
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (_isJurnalExist)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.info_circle,
                                size: 18,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sudah ada jurnal untuk jadwal ini',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Form Inputs
                  _buildInputSection(
                    icon: Iconsax.document_text,
                    title: 'Materi yang Diajarkan',
                    hint: 'Masukkan materi yang diajarkan',
                    controller: _materiController,
                    maxLines: 4,
                    isRequired: true,
                    theme: theme,
                  ),
                  const SizedBox(height: 20),

                  _buildInputSection(
                    icon: Iconsax.warning_2,
                    title: 'Kendala',
                    hint: 'Masukkan kendala yang dihadapi (opsional)',
                    controller: _kendalaController,
                    maxLines: 3,
                    theme: theme,
                  ),
                  const SizedBox(height: 20),

                  _buildInputSection(
                    icon: Iconsax.lamp_charge,
                    title: 'Solusi',
                    hint: 'Masukkan solusi yang dilakukan (opsional)',
                    controller: _solusiController,
                    maxLines: 3,
                    theme: theme,
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child:
                          _isLoading
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                              : Text(
                                'SIMPAN JURNAL',
                                style: theme.textTheme.labelLarge?.copyWith(
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
      ),
    );
  }

  Widget _buildInputSection({
    required IconData icon,
    required String title,
    required String hint,
    required TextEditingController controller,
    required int maxLines,
    required ThemeData theme,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withAlpha(100),
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
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
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
