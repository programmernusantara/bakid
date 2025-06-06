import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddEditGuruProfilePage extends StatefulWidget {
  final Map<String, dynamic>? guruData;

  const AddEditGuruProfilePage({super.key, this.guruData});

  bool get isEditMode => guruData != null;

  @override
  State<AddEditGuruProfilePage> createState() => _AddEditGuruProfilePageState();
}

class _AddEditGuruProfilePageState extends State<AddEditGuruProfilePage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _namaLengkapController = TextEditingController();
  final _jabatanController = TextEditingController();
  final _nomorTeleponController = TextEditingController();
  final _asalDaerahController = TextEditingController();
  final _alamatController = TextEditingController();

  bool _isLoading = false;
  bool _isActive = true;
  File? _imageFile;
  String? _imageUrl;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _namaLengkapController.text = widget.guruData!['nama_lengkap'] ?? '';
      _jabatanController.text = widget.guruData!['jabatan'] ?? '';
      _nomorTeleponController.text = widget.guruData!['nomor_telepon'] ?? '';
      _asalDaerahController.text = widget.guruData!['asal_daerah'] ?? '';
      _alamatController.text = widget.guruData!['alamat'] ?? '';
      _isActive = widget.guruData!['is_active'] ?? true;
      _imageUrl = widget.guruData!['foto_url'];

      final userData = widget.guruData!['pengguna'] ?? {};
      _usernameController.text = userData['nama'] ?? '';
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      if (mounted) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageUrl = null; // Reset URL jika memilih gambar baru
        });
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _imageUrl;

    if (!mounted) return null;
    setState(() => _isUploadingImage = true);

    try {
      final fileExt = _imageFile!.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'guru-profiles/$fileName';

      // Upload file tanpa menyimpan response
      await supabase.storage
          .from('profile-guru')
          .upload(
            filePath,
            _imageFile!,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: false,
            ),
          );

      // Dapatkan URL publik
      final imageUrl = supabase.storage
          .from('profile-guru')
          .getPublicUrl(filePath);

      // Hapus gambar lama jika ada
      if (widget.isEditMode &&
          widget.guruData?['foto_url'] != null &&
          mounted) {
        final oldUrl = widget.guruData!['foto_url'] as String;
        final oldFileName = oldUrl.split('/').last;
        try {
          await supabase.storage.from('profile-guru').remove([
            'guru-profiles/$oldFileName',
          ]);
        } catch (e) {
          if (mounted) {
            debugPrint('Gagal hapus gambar lama: $e');
          }
        }
      }

      return imageUrl;
    } on StorageException catch (e) {
      debugPrint('Error upload: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload gagal: ${e.message}')));
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
      final imageUrl = await _uploadImage();
      if (!mounted) return;

      if (widget.isEditMode) {
        // Update existing guru
        await supabase
            .from('profil_guru')
            .update({
              'nama_lengkap': _namaLengkapController.text,
              'jabatan': _jabatanController.text,
              'nomor_telepon': _nomorTeleponController.text,
              'asal_daerah': _asalDaerahController.text,
              'alamat': _alamatController.text,
              'is_active': _isActive,
              'foto_url': imageUrl ?? _imageUrl,
              'diperbarui_pada': DateTime.now().toIso8601String(),
            })
            .eq('id', widget.guruData!['id']);
      } else {
        // Create new user first
        final userResponse =
            await supabase
                .from('pengguna')
                .insert({
                  'nama': _usernameController.text,
                  'password_hash': _passwordController.text,
                  'peran': 'guru',
                })
                .select()
                .single();

        // Then create guru profile
        await supabase.from('profil_guru').insert({
          'user_id': userResponse['id'],
          'nama_lengkap': _namaLengkapController.text,
          'jabatan': _jabatanController.text,
          'nomor_telepon': _nomorTeleponController.text,
          'asal_daerah': _asalDaerahController.text,
          'alamat': _alamatController.text,
          'is_active': true,
          'foto_url': imageUrl,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditMode
                  ? 'Profil berhasil diperbarui'
                  : 'Guru baru berhasil ditambahkan',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Database error: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditMode ? 'Edit Profil Guru' : 'Tambah Guru Baru',
        ),
        actions: [
          if (widget.isEditMode)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _submitForm,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.outlineVariant,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            _isUploadingImage
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : _imageFile != null
                                ? Image.file(_imageFile!, fit: BoxFit.cover)
                                : _imageUrl != null
                                ? Image.network(_imageUrl!, fit: BoxFit.cover)
                                : Icon(
                                  Icons.person,
                                  size: 60,
                                  color: colors.outline,
                                ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: colors.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _pickImage,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: colors.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!widget.isEditMode) ...[
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: colors.outline,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username wajib diisi';
                    }
                    if (value.length < 3) {
                      return 'Username minimal 3 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline, color: colors.outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: colors.outline,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password wajib diisi';
                    }
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_confirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    prefixIcon: Icon(Icons.lock_outline, color: colors.outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: colors.outline,
                      ),
                      onPressed: () {
                        setState(() {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Password tidak cocok';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _namaLengkapController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.badge_outlined, color: colors.outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama lengkap wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jabatanController,
                decoration: InputDecoration(
                  labelText: 'Jabatan',
                  prefixIcon: Icon(Icons.work_outline, color: colors.outline),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomorTeleponController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Nomor Telepon',
                  prefixIcon: Icon(Icons.phone_outlined, color: colors.outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      !RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Hanya boleh berisi angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _asalDaerahController,
                decoration: InputDecoration(
                  labelText: 'Asal Daerah',
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: colors.outline,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alamatController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Alamat',
                  prefixIcon: Icon(Icons.home_outlined, color: colors.outline),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (widget.isEditMode) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Status Aktif'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
              const SizedBox(height: 32),
              if (!widget.isEditMode)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Simpan Data Guru'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _namaLengkapController.dispose();
    _jabatanController.dispose();
    _nomorTeleponController.dispose();
    _asalDaerahController.dispose();
    _alamatController.dispose();
    super.dispose();
  }
}
