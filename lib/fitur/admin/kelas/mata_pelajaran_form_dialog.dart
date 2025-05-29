import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bakid/fitur/admin/kelas/provider_management_kelas.dart';

class MataPelajaranFormDialog extends ConsumerStatefulWidget {
  final String kelasId;
  final Map<String, dynamic>? mataPelajaranData;

  const MataPelajaranFormDialog({
    super.key,
    required this.kelasId,
    this.mataPelajaranData,
  });

  @override
  ConsumerState<MataPelajaranFormDialog> createState() =>
      _MataPelajaranFormDialogState();
}

class _MataPelajaranFormDialogState
    extends ConsumerState<MataPelajaranFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _deskripsiController;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(
      text: widget.mataPelajaranData?['nama'] ?? '',
    );
    _deskripsiController = TextEditingController(
      text: widget.mataPelajaranData?['deskripsi'] ?? '',
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.mataPelajaranData != null;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEdit ? 'Edit Mata Pelajaran' : 'Tambah Mata Pelajaran',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Mata Pelajaran',
                hintText: 'Matematika',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama mata pelajaran harus diisi';
                }
                if (value.length < 3) {
                  return 'Minimal 3 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deskripsiController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                hintText: 'Penjelasan singkat mata pelajaran',
                border: OutlineInputBorder(),
              ),
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

  // Di MataPelajaranFormDialog
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(mataPelajaranServiceProvider);
    final data = {
      'kelas_id': widget.kelasId,
      'nama': _namaController.text.trim(),
      'deskripsi': _deskripsiController.text.trim(),
    };

    try {
      if (widget.mataPelajaranData == null) {
        await service.addMataPelajaran(data);
      } else {
        await service.updateMataPelajaran(
          widget.mataPelajaranData!['id'],
          data,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              widget.mataPelajaranData == null
                  ? 'Mata pelajaran berhasil ditambahkan'
                  : 'Mata pelajaran berhasil diperbarui',
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
}
