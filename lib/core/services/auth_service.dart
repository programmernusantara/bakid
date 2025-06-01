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
  static const _lastUsernameKey = 'last_username';
  static const _rememberMeKey = 'remember_me';

  AuthService(this._supabase, this._sharedPrefs);

  Future<Map<String, dynamic>?> login(
    String username,
    String password, {
    bool rememberMe = true,
  }) async {
    try {
      final response =
          await _supabase
              .from('pengguna')
              .select()
              .eq('nama', username)
              .maybeSingle();

      if (response == null) {
        throw 'Username atau password salah';
      }

      if (response['password_hash'] != password) {
        throw 'Username atau password salah';
      }

      if (response['peran'] == 'guru') {
        final profil =
            await _supabase
                .from('profil_guru')
                .select()
                .eq('user_id', response['id'])
                .maybeSingle();

        if (profil != null) {
          response.addAll({'profil': profil});
        }
      }

      await _supabase
          .from('pengguna')
          .update({'terakhir_login': DateTime.now().toIso8601String()})
          .eq('id', response['id']);

      await _saveUserData(response, rememberMe: rememberMe);

      return response;
    } on PostgrestException {
      throw 'Terjadi kesalahan saat mengakses database';
    }
  }

  Future<void> _saveUserData(
    Map<String, dynamic> userData, {
    bool rememberMe = true,
  }) async {
    await _sharedPrefs.setString(_userKey, jsonEncode(userData));
    await _sharedPrefs.setBool(_rememberMeKey, rememberMe);

    if (rememberMe) {
      await _sharedPrefs.setString(_lastUsernameKey, userData['nama'] ?? '');
    } else {
      await _sharedPrefs.remove(_lastUsernameKey);
    }
  }

  Future<Map<String, dynamic>?> getStoredUser() async {
    try {
      final userJson = _sharedPrefs.getString(_userKey);
      if (userJson == null) return null;
      return jsonDecode(userJson) as Map<String, dynamic>;
    } catch (_) {
      await _sharedPrefs.remove(_userKey);
      return null;
    }
  }

  Future<String?> getLastUsername() async {
    final rememberMe = _sharedPrefs.getBool(_rememberMeKey) ?? false;
    if (!rememberMe) return null;
    return _sharedPrefs.getString(_lastUsernameKey);
  }

  Future<void> logout() async {
    try {
      // Bersihkan semua data pengguna dari SharedPreferences
      await _sharedPrefs.remove(_userKey);
      await _sharedPrefs.remove(_lastUsernameKey);
      await _sharedPrefs.remove(_rememberMeKey);
    } catch (e) {
      debugPrint('Error during logout: $e');
      rethrow; // Re-throw exception untuk ditangani di UI
    }
  }

  Future<void> clearAllUserData() async {
    await _sharedPrefs.remove(_userKey);
    await _sharedPrefs.remove(_lastUsernameKey);
    await _sharedPrefs.remove(_rememberMeKey);
  }

  Stream<Map<String, dynamic>?> authStateChanges() {
    return _supabase.auth.onAuthStateChange.asyncMap((authState) async {
      // Tambahkan pengecekan event untuk langsung memperbarui state
      if (authState.event == AuthChangeEvent.signedIn) {
        return await getStoredUser();
      } else if (authState.event == AuthChangeEvent.signedOut) {
        return null;
      }
      return await getStoredUser();
    });
  }
}
