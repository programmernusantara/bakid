import 'dart:convert';
import 'package:bakid/fitur/auth/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final supabaseProvider = Provider((ref) => Supabase.instance.client);

final authServiceProvider = Provider<AuthService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final sharedPrefs = ref.watch(sharedPrefsProvider);
  return AuthService(supabase, sharedPrefs);
});

class AuthService {
  final SupabaseClient _supabase;
  final SharedPreferences _sharedPrefs;

  static const _userKey = 'current_user_data';
  static const _sessionKey = 'current_session';

  AuthService(this._supabase, this._sharedPrefs);

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      // 1. Cari pengguna berdasarkan username
      final userResponse =
          await _supabase
              .from('pengguna')
              .select()
              .eq('nama', username)
              .maybeSingle();

      if (userResponse == null) throw 'Pengguna tidak ditemukan';

      // 2. Verifikasi password (dalam implementasi nyata, gunakan hashing)
      // Ini hanya contoh - dalam produksi gunakan hashing yang aman
      if (userResponse['password_hash'] != password) {
        throw 'Password salah';
      }

      // 3. Dapatkan profil guru jika role adalah guru
      Map<String, dynamic>? profile;
      if (userResponse['peran'] == 'guru') {
        profile =
            await _supabase
                .from('profil_guru')
                .select()
                .eq('user_id', userResponse['id'])
                .maybeSingle();
      }

      // 4. Update waktu login terakhir
      await _supabase
          .from('pengguna')
          .update({
            'terakhir_login': DateTime.now().toUtc().toIso8601String(),
            'diperbarui_pada': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userResponse['id']);

      // 5. Gabungkan data user dan profile
      final userData = {
        ...userResponse,
        if (profile != null) 'profil': profile,
      };

      // 6. Simpan data user ke shared preferences
      await _saveUserData(userData);

      return userData;
    } on PostgrestException catch (e) {
      debugPrint('Login error: ${e.message}');
      throw 'Terjadi kesalahan saat mengakses database';
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      await _sharedPrefs.setString(_userKey, jsonEncode(userData));
    } catch (e) {
      debugPrint('Error saving user data: $e');
      throw 'Gagal menyimpan data login';
    }
  }

  Future<Map<String, dynamic>?> getStoredUser() async {
    try {
      final userJson = _sharedPrefs.getString(_userKey);
      if (userJson == null) return null;
      return jsonDecode(userJson) as Map<String, dynamic>;
    } catch (e) {
      await _sharedPrefs.remove(_userKey);
      debugPrint('Error getting stored user: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      // Clear Supabase session first
      await _supabase.auth.signOut();

      // Then clear local storage
      await _sharedPrefs.remove(_userKey);
      await _sharedPrefs.remove(_sessionKey);

      // Add small delay to ensure all cleanup is done
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      debugPrint('Error during logout: $e');
      rethrow;
    }
  }

  Stream<Map<String, dynamic>?> authStateChanges() {
    return _supabase.auth.onAuthStateChange.asyncMap((authState) async {
      try {
        if (authState.event == AuthChangeEvent.signedOut) {
          await _sharedPrefs.remove(_userKey);
          await _sharedPrefs.remove(_sessionKey);
          return null;
        }
        return await getStoredUser();
      } catch (e) {
        debugPrint('Auth state error: $e');
        await _sharedPrefs.remove(_userKey);
        return null;
      }
    });
  }
}
