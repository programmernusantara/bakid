import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bakid/fitur/admin/kelas/provider_management_kelas.dart';

class JadwalFormDialog extends ConsumerStatefulWidget {
  final String kelasId;
  final Map<String, dynamic>? jadwalData;

  const JadwalFormDialog({super.key, required this.kelasId, this.jadwalData});

  @override
  ConsumerState<JadwalFormDialog> createState() => _JadwalFormDialogState();
}

class _JadwalFormDialogState extends ConsumerState<JadwalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late int _hari;
  late TimeOfDay _waktuMulai;
  late TimeOfDay _waktuSelesai;
  String? _mataPelajaranId;
  String? _guruId;
  String? _lokasiAbsenId;

  @override
  void initState() {
    super.initState();
    _hari = widget.jadwalData?['hari_dalam_minggu'] ?? 1;
    _waktuMulai = _parseTime(widget.jadwalData?['waktu_mulai'] ?? '07:00');
    _waktuSelesai = _parseTime(widget.jadwalData?['waktu_selesai'] ?? '08:00');
    _mataPelajaranId = widget.jadwalData?['mata_pelajaran_id'];
    _guruId = widget.jadwalData?['guru_id'];
    _lokasiAbsenId = widget.jadwalData?['lokasi_absen_id'];
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEdit = widget.jadwalData != null;

    final mataPelajaranAsync = ref.watch(
      mataPelajaranByKelasProvider(widget.kelasId),
    );
    final guruAsync = ref.watch(guruListProvider);
    final lokasiAsync = ref.watch(lokasiAbsenListProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Edit Jadwal' : 'Tambah Jadwal',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Hari Dropdown
            DropdownButtonFormField<int>(
              value: _hari,
              items:
                  List.generate(7, (i) => i + 1)
                      .map(
                        (day) => DropdownMenuItem(
                          value: day,
                          child: Text(_getHariName(day)),
                        ),
                      )
                      .toList(),
              onChanged: (val) => setState(() => _hari = val!),
              decoration: const InputDecoration(
                labelText: 'Hari*',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null ? 'Pilih hari' : null,
            ),
            const SizedBox(height: 16),

            // Waktu Mulai dan Selesai
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: _waktuMulai.format(context),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Waktu Mulai*',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _waktuMulai,
                      );
                      if (time != null) setState(() => _waktuMulai = time);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: _waktuSelesai.format(context),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Waktu Selesai*',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _waktuSelesai,
                      );
                      if (time != null) setState(() => _waktuSelesai = time);
                    },
                    validator: (val) {
                      if (_waktuSelesai.hour < _waktuMulai.hour ||
                          (_waktuSelesai.hour == _waktuMulai.hour &&
                              _waktuSelesai.minute <= _waktuMulai.minute)) {
                        return 'Waktu selesai harus setelah waktu mulai';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mata Pelajaran Dropdown
            mataPelajaranAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (e, _) =>
                      Text('Error: $e', style: TextStyle(color: colors.error)),
              data:
                  (mataPelajaranList) => DropdownButtonFormField<String>(
                    value: _mataPelajaranId,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Pilih Mata Pelajaran'),
                      ),
                      ...mataPelajaranList.map(
                        (mp) => DropdownMenuItem(
                          value: mp['id'],
                          child: Text(mp['nama']),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _mataPelajaranId = val),
                    decoration: const InputDecoration(
                      labelText: 'Mata Pelajaran*',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (val) => val == null ? 'Pilih mata pelajaran' : null,
                  ),
            ),
            const SizedBox(height: 16),

            // Guru Dropdown
            // Guru Dropdown
            guruAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (e, _) =>
                      Text('Error: $e', style: TextStyle(color: colors.error)),
              data:
                  (guruList) => DropdownButtonFormField<String>(
                    value: _guruId,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Pilih Guru'),
                      ),
                      ...guruList.map(
                        (guru) => DropdownMenuItem(
                          value: guru['id'],
                          child: Text(
                            '${guru['nama_lengkap']} (${guru['asal_daerah'] ?? '-'})',
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _guruId = val),
                    decoration: const InputDecoration(
                      labelText: 'Guru',
                      border: OutlineInputBorder(),
                    ),
                  ),
            ),
            const SizedBox(height: 16),

            // Lokasi Absen Dropdown
            lokasiAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (e, _) =>
                      Text('Error: $e', style: TextStyle(color: colors.error)),
              data:
                  (lokasiList) => DropdownButtonFormField<String>(
                    value: _lokasiAbsenId,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Pilih Lokasi Absen'),
                      ),
                      ...lokasiList.map(
                        (lokasi) => DropdownMenuItem(
                          value: lokasi['id'],
                          child: Text(lokasi['nama']),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _lokasiAbsenId = val),
                    decoration: const InputDecoration(
                      labelText: 'Lokasi Absen',
                      border: OutlineInputBorder(),
                    ),
                  ),
            ),
            const SizedBox(height: 24),

            // Tombol Aksi
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Di JadwalFormDialog
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final data = {
      'kelas_id': widget.kelasId,
      'hari_dalam_minggu': _hari,
      'waktu_mulai': _formatTime(_waktuMulai),
      'waktu_selesai': _formatTime(_waktuSelesai),
      'mata_pelajaran_id': _mataPelajaranId,
      'guru_id': _guruId,
      'lokasi_absen_id': _lokasiAbsenId,
      'aktif': true,
    };

    try {
      final service = ref.read(jadwalMengajarServiceProvider);
      if (widget.jadwalData == null) {
        await service.addJadwal(data);
      } else {
        await service.updateJadwal(widget.jadwalData!['id'], data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              widget.jadwalData == null
                  ? 'Jadwal berhasil ditambahkan'
                  : 'Jadwal berhasil diperbarui',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
  }

  String _getHariName(int hari) {
    switch (hari) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return 'Hari tidak dikenal';
    }
  }
}
