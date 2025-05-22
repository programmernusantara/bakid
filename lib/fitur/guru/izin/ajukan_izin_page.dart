// ajukan_izin_page.dart
import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/fitur/guru/izin/izin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';

class AjukanIzinPage extends ConsumerStatefulWidget {
  const AjukanIzinPage({super.key});

  @override
  ConsumerState<AjukanIzinPage> createState() => _AjukanIzinPageState();
}

class _AjukanIzinPageState extends ConsumerState<AjukanIzinPage> {
  final _formKey = GlobalKey<FormState>();
  final _alasanController = TextEditingController();
  String? _jenisIzin;
  String? _selectedScheduleId;
  bool _isLoading = false;

  final List<String> _jenisIzinList = [
    'Sakit',
    'Keluarga',
    'Urusan Pribadi',
    'Lainnya',
  ];

  // In the _submitIzin method of AjukanIzinPage
  Future<void> _submitIzin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_jenisIzin == null || _selectedScheduleId == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null || user['profil'] == null) return;

    setState(() => _isLoading = true);
    try {
      final supabase = ref.read(supabaseProvider);
      final today = DateTime.now();

      await supabase.from('permohonan_izin').insert({
        'guru_id': user['profil']['id'],
        'jadwal_id': _selectedScheduleId,
        'jenis_izin': _jenisIzin,
        'tanggal_efektif': today.toIso8601String(),
        'alasan': _alasanController.text,
        'status': 'menunggu',
      });

      if (!mounted) return;

      // Invalidate the provider to force refresh
      ref.invalidate(jadwalHariIniProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Permohonan izin berhasil diajukan'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Return true to indicate success and trigger refresh
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengajukan izin: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jadwalFuture = ref.watch(jadwalHariIniProvider);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Ajukan Izin',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: jadwalFuture.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (jadwal) {
          if (jadwal.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Anda tidak mempunyai jadwal\nuntuk izin hari ini',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pilih Jadwal
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
                  ...jadwal.map((j) {
                    final isSelected = _selectedScheduleId == j['id'];
                    final kelas = j['kelas'] as Map<String, dynamic>?;
                    final mapel = j['mata_pelajaran'] as Map<String, dynamic>?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color:
                              isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() => _selectedScheduleId = j['id']);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Theme.of(
                                            context,
                                          ).primaryColor.withAlpha(100)
                                          : Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.schedule_outlined,
                                  color:
                                      isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${mapel?['nama'] ?? 'Mata Pelajaran'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isSelected
                                                ? Theme.of(context).primaryColor
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
                                  color: Theme.of(context).primaryColor,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Jenis Izin
                  Text(
                    'JENIS IZIN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _jenisIzin,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
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
                    hint: const Text('Pilih Jenis Izin'),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    borderRadius: BorderRadius.circular(12),
                    style: TextStyle(color: Colors.grey[800], fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Alasan Izin
                  Text(
                    'ALASAN IZIN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _alasanController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      hintText: 'Masukkan alasan izin Anda',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harap isi alasan izin';
                      }
                      return null;
                    },
                    style: TextStyle(color: Colors.grey[800], fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  // Tombol Submit
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _submitIzin,
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
                              : const Text(
                                'AJUKAN IZIN',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
