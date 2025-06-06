import 'dart:io';
import 'package:bakid/fitur/admin/pengumuman/pengumuman_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
  File? _imageFile;
  String? _fotoUrl;
  String? _currentFotoUrl;
  bool _isUploadingImage = false;

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
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile == null || !mounted) return;

      setState(() {
        _imageFile = File(pickedFile.path);
        _fotoUrl = null;
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Gagal memilih gambar: ${e.toString()}');
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _currentFotoUrl;

    if (!mounted) return null;
    setState(() => _isUploadingImage = true);

    try {
      final pengumumanService = ref.read(pengumumanServiceProvider);
      final imageUrl = await pengumumanService.uploadImage(_imageFile!);

      // Hapus gambar lama jika ada
      if (widget.initialData != null &&
          widget.initialData!['foto_url'] != null) {
        await pengumumanService.deleteOldImage(widget.initialData!['foto_url']);
      }

      return imageUrl;
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Gagal mengunggah gambar: ${e.toString()}');
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final pengumumanService = ref.read(pengumumanServiceProvider);
      final imageUrl = await _uploadImage();
      if (!mounted) return;

      if (widget.initialData == null) {
        await pengumumanService.createPengumuman(
          judul: _judulController.text,
          isi: _isiController.text,
          fotoUrl: imageUrl,
          adminId: widget.adminId!,
        );
      } else {
        await pengumumanService.updatePengumuman(
          id: widget.initialData!['id'],
          judul: _judulController.text,
          isi: _isiController.text,
          fotoUrl: imageUrl ?? _currentFotoUrl,
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

  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.initialData != null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit Pengumuman' : 'Buat Pengumuman',
          style: const TextStyle(color: Colors.black87),
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

                  if (_isUploadingImage)
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  else if (_fotoUrl != null || _currentFotoUrl != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _fotoUrl ?? _currentFotoUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 180,
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  height: 180,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                  ),
                                ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              if (mounted) {
                                setState(() {
                                  _fotoUrl = null;
                                  _currentFotoUrl = null;
                                  _imageFile = null;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

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
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

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
