import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/features/guru/izin/jadwal_izin_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bakid/features/auth/auth_providers.dart';

class AjukanIzinPage extends ConsumerStatefulWidget {
  const AjukanIzinPage({super.key});

  @override
  ConsumerState<AjukanIzinPage> createState() => _AjukanIzinPageState();
}

class _AjukanIzinPageState extends ConsumerState<AjukanIzinPage> {
  final _formKey = GlobalKey<FormState>();
  final _alasanController = TextEditingController();
  DateTimeRange? _tanggalIzin;
  String? _jenisIzin;
  bool _isLoading = false;

  final List<String> _jenisIzinList = [
    'Sakit',
    'Keluarga',
    'Urusan Pribadi',
    'Lainnya',
  ];

  Future<void> _submitIzin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tanggalIzin == null || _jenisIzin == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null || user['profil'] == null) return;

    setState(() => _isLoading = true);
    try {
      final supabase = ref.read(supabaseProvider);

      // Validasi jadwal di tanggal izin
      final jadwal = await supabase
          .from('jadwal_mengajar')
          .select()
          .eq('guru_id', user['profil']['id'])
          .gte('tanggal', DateFormat('yyyy-MM-dd').format(_tanggalIzin!.start))
          .lte('tanggal', DateFormat('yyyy-MM-dd').format(_tanggalIzin!.end));

      if (jadwal.isEmpty) {
        throw 'Anda tidak memiliki jadwal mengajar di tanggal tersebut';
      }

      // Submit permohonan izin
      await supabase.from('permohonan_izin').insert({
        'guru_id': user['profil']['id'],
        'jenis_izin': _jenisIzin,
        'tanggal_mulai': DateFormat('yyyy-MM-dd').format(_tanggalIzin!.start),
        'tanggal_selesai': DateFormat('yyyy-MM-dd').format(_tanggalIzin!.end),
        'alasan': _alasanController.text,
        'status': 'menunggu',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permohonan izin berhasil diajukan')),
      );

      // Reset form
      _formKey.currentState?.reset();
      _alasanController.clear();
      setState(() {
        _tanggalIzin = null;
        _jenisIzin = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengajukan izin: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _tanggalIzin,
    );
    if (picked != null && picked != _tanggalIzin) {
      setState(() => _tanggalIzin = picked);
    }
  }

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pilih Tanggal Izin
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _tanggalIzin == null
                    ? 'Pilih Tanggal Izin'
                    : '${DateFormat('dd MMM yyyy').format(_tanggalIzin!.start)} '
                        '- ${DateFormat('dd MMM yyyy').format(_tanggalIzin!.end)}',
              ),
              onTap: () => _selectDateRange(context),
            ),
            const SizedBox(height: 16),

            // Jenis Izin
            DropdownButtonFormField<String>(
              value: _jenisIzin,
              decoration: const InputDecoration(
                labelText: 'Jenis Izin',
                border: OutlineInputBorder(),
              ),
              items:
                  _jenisIzinList.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() => _jenisIzin = value);
              },
              validator: (value) {
                if (value == null) return 'Pilih jenis izin';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Alasan Izin
            TextFormField(
              controller: _alasanController,
              decoration: const InputDecoration(
                labelText: 'Alasan Izin',
                border: OutlineInputBorder(),
                hintText: 'Jelaskan alasan izin Anda',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Harap isi alasan izin';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Jadwal yang Terpengaruh
            const Text(
              'Jadwal yang Terpengaruh:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const JadwalIzinDropdown(),
            const SizedBox(height: 24),

            // Tombol Submit
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitIzin,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('AJUKAN IZIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
