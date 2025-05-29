import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bakid/fitur/admin/kelas/provider_management_kelas.dart';

class KelasFormDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? kelasData;

  const KelasFormDialog({super.key, this.kelasData});

  @override
  ConsumerState<KelasFormDialog> createState() => _KelasFormDialogState();
}

class _KelasFormDialogState extends ConsumerState<KelasFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _waliKelasController;
  late TextEditingController _tahunAjaranController;
  late TextEditingController _jumlahMuridController;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.kelasData?['nama']);
    _waliKelasController = TextEditingController(
      text: widget.kelasData?['wali_kelas'],
    );
    _tahunAjaranController = TextEditingController(
      text: widget.kelasData?['tahun_ajaran'],
    );
    _jumlahMuridController = TextEditingController(
      text: widget.kelasData?['jumlah_murid']?.toString(),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _waliKelasController.dispose();
    _tahunAjaranController.dispose();
    _jumlahMuridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.kelasData == null ? 'Tambah Kelas' : 'Edit Kelas',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Kelas',
                hintText: 'X IPA 1',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama kelas harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _waliKelasController,
              decoration: const InputDecoration(
                labelText: 'Wali Kelas',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tahunAjaranController,
              decoration: const InputDecoration(
                labelText: 'Tahun Ajaran',
                hintText: '2024/2025',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tahun ajaran harus diisi';
                }
                if (!RegExp(r'^\d{4}/\d{4}$').hasMatch(value)) {
                  return 'Format tahun ajaran tidak valid (contoh: 2024/2025)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _jumlahMuridController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Murid',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah murid harus diisi';
                }
                if (int.tryParse(value) == null) {
                  return 'Harus berupa angka';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'nama': _namaController.text,
      'wali_kelas': _waliKelasController.text,
      'tahun_ajaran': _tahunAjaranController.text,
      'jumlah_murid': int.parse(_jumlahMuridController.text),
    };

    try {
      final kelasService = ref.read(kelasServiceProvider);

      if (widget.kelasData == null) {
        await kelasService.addKelas(data);
      } else {
        await kelasService.updateKelas(widget.kelasData!['id'], data);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.kelasData == null
                  ? 'Kelas berhasil ditambahkan'
                  : 'Kelas berhasil diperbarui',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: ${e.toString()}')),
        );
      }
    }
  }
}
