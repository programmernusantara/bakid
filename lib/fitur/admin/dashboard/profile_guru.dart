import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class GuruManagementPage extends ConsumerStatefulWidget {
  const GuruManagementPage({super.key});

  @override
  ConsumerState<GuruManagementPage> createState() => _GuruManagementPageState();
}

class _GuruManagementPageState extends ConsumerState<GuruManagementPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSearching = false;
  List<Map<String, dynamic>> _guruList = [];
  List<Map<String, dynamic>> _filteredGuruList = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGuruList =
          query.isEmpty
              ? List.from(_guruList)
              : _guruList.where((guru) {
                final namaGuru =
                    guru['nama_lengkap']?.toString().toLowerCase() ?? '';
                final namaUser =
                    guru['pengguna']?['nama']?.toString().toLowerCase() ?? '';
                return namaGuru.contains(query) || namaUser.contains(query);
              }).toList();
    });
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('profil_guru')
          .select('*, pengguna(id, nama, peran)')
          .order('dibuat_pada', ascending: false);

      if (!mounted) return;

      setState(() {
        _guruList = List<Map<String, dynamic>>.from(response);
        _filteredGuruList = List.from(_guruList);
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Gagal memuat data: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteGuru(Map<String, dynamic> guru) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text(
              'Hapus guru ${guru['nama_lengkap']}? Akun pengguna juga akan dihapus.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      // Delete user account first (will cascade to profile via foreign key)
      await supabase.from('pengguna').delete().eq('id', guru['pengguna']['id']);

      if (mounted) {
        _showSuccessSnackbar('Data guru berhasil dihapus');
        await _fetchData();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Gagal hapus data: ${e.toString()}');
      }
    }
  }

  Future<void> _updateActiveStatus(String id, bool currentStatus) async {
    try {
      await supabase
          .from('profil_guru')
          .update({'is_active': !currentStatus})
          .eq('id', id);
      await _fetchData();
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Gagal mengubah status: ${e.toString()}');
      }
    }
  }

  void _showAddProfileDialog() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const AddEditGuruProfilePage(),
          ),
        )
        .then((_) => _fetchData());
  }

  void _showEditProfileDialog(Map<String, dynamic> guruData) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddEditGuruProfilePage(guruData: guruData),
          ),
        )
        .then((_) => _fetchData());
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildGuruCard(Map<String, dynamic> guru) {
    final bool isActive = guru['is_active'] ?? true;
    final user = guru['pengguna'] ?? {};
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      guru['foto_url'] != null
                          ? NetworkImage(guru['foto_url'])
                          : null,
                  child:
                      guru['foto_url'] == null
                          ? const Icon(Icons.person, size: 28)
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guru['nama_lengkap'] ?? '-',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['nama'] ?? '-',
                        style: TextStyle(color: colors.outline, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _updateActiveStatus(guru['id'], isActive),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? colors.surfaceContainerHighest
                              : colors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(
                        color:
                            isActive
                                ? colors.onSurfaceVariant
                                : colors.onErrorContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.work_outline, 'Jabatan', guru['jabatan']),
            _buildInfoRow(
              Icons.phone_outlined,
              'Telepon',
              guru['nomor_telepon'],
            ),
            _buildInfoRow(
              Icons.location_on_outlined,
              'Daerah',
              guru['asal_daerah'],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: colors.primary),
                  onPressed: () => _showEditProfileDialog(guru),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colors.error),
                  onPressed: () => _deleteGuru(guru),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.outline),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value ?? '-',
              style: TextStyle(fontSize: 14, color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Cari guru...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  style: TextStyle(color: colors.onSurface),
                  cursorColor: colors.primary,
                  onChanged: (value) => setState(() {}),
                )
                : null,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: colors.primary,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProfileDialog,
        mini: true,
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredGuruList.isEmpty
              ? Center(
                child: Text(
                  'Belum ada data guru',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemCount: _filteredGuruList.length,
                itemBuilder:
                    (context, index) =>
                        _buildGuruCard(_filteredGuruList[index]),
              ),
    );
  }
}

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
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final fileExt = _imageFile!.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'guru_profile/$fileName';

      await supabase.storage.from('guru_profile').upload(filePath, _imageFile!);

      return supabase.storage.from('guru_profile').getPublicUrl(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah gambar: ${e.toString()}')),
        );
      }
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!widget.isEditMode &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password tidak cocok')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrl = await _uploadImage() ?? _imageUrl;

      if (widget.isEditMode) {
        await supabase
            .from('profil_guru')
            .update({
              'nama_lengkap': _namaLengkapController.text,
              'jabatan': _jabatanController.text,
              'nomor_telepon': _nomorTeleponController.text,
              'asal_daerah': _asalDaerahController.text,
              'alamat': _alamatController.text,
              'is_active': _isActive,
              'foto_url': imageUrl,
              'diperbarui_pada': DateTime.now().toIso8601String(),
            })
            .eq('id', widget.guruData!['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil berhasil diperbarui')),
          );
          Navigator.pop(context);
        }
      } else {
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guru baru berhasil ditambahkan')),
          );
          Navigator.pop(context);
        }
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
            IconButton(icon: const Icon(Icons.save), onPressed: _submitForm),
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
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            _imageFile != null
                                ? FileImage(_imageFile!)
                                : _imageUrl != null
                                ? NetworkImage(_imageUrl!)
                                : null,
                        child:
                            _imageFile == null && _imageUrl == null
                                ? const Icon(Icons.person, size: 50)
                                : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.surface, width: 2),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 18,
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator()
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
