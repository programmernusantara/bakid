import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class untuk mengelola interaksi dengan Supabase.
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Mendapatkan user yang sedang login
  User? get currentUser => _client.auth.currentUser;

  /// Stream perubahan status autentikasi
  Stream<User?> authStateChanges() =>
      _client.auth.onAuthStateChange.map((event) => event.session?.user);

  // ============================
  // AUTENTIKASI
  // ============================

  /// Login menggunakan email dan password
  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      debugPrint('Login AuthException: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('Login error: $e');
      throw Exception('Terjadi kesalahan saat login.');
    }
  }

  /// Logout dari aplikasi
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  // ============================
  // PEMBAYARAN & AKADEMIK
  // ============================

  Future<List<Map<String, dynamic>>> fetchPayments(String santriId) async {
    try {
      final data = await _client
          .from('pembayaran')
          .select(
            'id, nama_pembayaran, jumlah, jatuh_tempo, tanggal_bayar, status',
          )
          .eq('santri_id', santriId)
          .order('dibuat_pada', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetchPayments: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAcademicRecords(
    String santriId,
  ) async {
    try {
      final data = await _client
          .from('akademik')
          .select()
          .eq('santri_id', santriId)
          .order('semester', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetchAcademicRecords: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchStudentProfile(String userId) async {
    try {
      final data =
          await _client.from('santri').select().eq('id', userId).maybeSingle();

      return data;
    } catch (e) {
      debugPrint('Error fetchStudentProfile: $e');
      return null;
    }
  }

  // ============================
  // ABSENSI
  // ============================

  Future<List<Map<String, dynamic>>> fetchDailyAttendance(
    String santriId,
  ) async {
    try {
      final data = await _client
          .from('absensi_harian')
          .select()
          .eq('santri_id', santriId)
          .order('tanggal', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetchDailyAttendance: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchMonthlyAttendance(
    String santriId,
  ) async {
    try {
      final data = await _client
          .from('rekap_bulanan')
          .select()
          .eq('santri_id', santriId)
          .order('tahun', ascending: false)
          .order('bulan', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetchMonthlyAttendance: $e');
      return [];
    }
  }

  // ============================
  // PENGUMUMAN (REALTIME)
  // ============================

  /// Mendapatkan stream realtime pengumuman saja
  Stream<List<Map<String, dynamic>>> getPengumumanStream() {
    return _client
        .from('pengumuman')
        .stream(primaryKey: ['id'])
        .order('dibuat_pada', ascending: false);
  }
}
