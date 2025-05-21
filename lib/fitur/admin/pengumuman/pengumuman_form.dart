import 'package:bakid/fitur/admin/pengumuman/pengumuman_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PengumumanFormPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;
  final String? adminId;

  const PengumumanFormPage({super.key, this.initialData, this.adminId});

  @override
  ConsumerState<PengumumanFormPage> createState() => _PengumumanFormPageState();
}

class _PengumumanFormPageState extends ConsumerState<PengumumanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _isiController = TextEditingController();
  final _picker = ImagePicker();

  bool _isLoading = false;
  bool _aktif = true;
  String? _fotoUrl;
  String? _currentFotoUrl;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _judulController.text = widget.initialData!['judul'] ?? '';
      _isiController.text = widget.initialData!['isi'] ?? '';
      _aktif = widget.initialData!['aktif'] ?? true;
      _currentFotoUrl = widget.initialData!['foto_url'];
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _isiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null || !mounted) return;

      setState(() => _isLoading = true);

      final supabase = Supabase.instance.client;
      final bytes = await pickedFile.readAsBytes();
      final fileExt = pickedFile.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final filePath = 'pengumuman/$fileName';

      await supabase.storage
          .from('pengumuman')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: pickedFile.mimeType),
          );

      final imageUrl = supabase.storage
          .from('pengumuman')
          .getPublicUrl(filePath);

      if (mounted) {
        setState(() {
          _fotoUrl = imageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Gagal mengunggah gambar: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final pengumumanService = ref.read(pengumumanServiceProvider);

      if (widget.initialData == null) {
        await pengumumanService.createPengumuman(
          judul: _judulController.text,
          isi: _isiController.text,
          fotoUrl: _fotoUrl,
          adminId: widget.adminId!,
        );
      } else {
        await pengumumanService.updatePengumuman(
          id: widget.initialData!['id'],
          judul: _judulController.text,
          isi: _isiController.text,
          fotoUrl: _fotoUrl ?? _currentFotoUrl,
          aktif: _aktif,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.initialData != null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit Pengumuman' : 'Buat Pengumuman',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                Navigator.pop(context, false);
                Navigator.pop(context, true);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Judul Field
              TextFormField(
                controller: _judulController,
                decoration: InputDecoration(
                  labelText: 'Judul Pengumuman',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'Judul harus diisi' : null,
              ),
              const SizedBox(height: 16),

              // Isi Field
              TextFormField(
                controller: _isiController,
                decoration: InputDecoration(
                  labelText: 'Isi Pengumuman',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 5,
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'Isi harus diisi' : null,
              ),
              const SizedBox(height: 16),

              // Status Switch (hanya di edit mode)
              if (isEditMode)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SwitchListTile(
                    title: const Text('Aktifkan Pengumuman'),
                    value: _aktif,
                    onChanged: (value) => setState(() => _aktif = value),
                  ),
                ),
              const SizedBox(height: 16),

              // Image Upload Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gambar Pengumuman',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Image Preview
                  if (_fotoUrl != null || _currentFotoUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _fotoUrl ?? _currentFotoUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              height: 180,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 50),
                            ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Upload Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Pilih Gambar'),
                      onPressed: _isLoading ? null : _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            isEditMode
                                ? 'UPDATE PENGUMUMAN'
                                : 'SIMPAN PENGUMUMAN',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
