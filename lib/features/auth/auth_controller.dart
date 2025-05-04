import 'package:bakid/core/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final SupabaseService _supabase;

  AuthController(this._supabase) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Gunakan currentUser dari SupabaseService
    final currentUser = _supabase.currentUser;
    if (currentUser != null) {
      state = AsyncValue.data(currentUser);
    }

    // Listen for auth changes
    _supabase.authStateChanges().listen((user) {
      state = AsyncValue.data(user);
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      await _supabase.signInWithEmailAndPassword(email, password);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      state = const AsyncValue.loading();
      await _supabase.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
