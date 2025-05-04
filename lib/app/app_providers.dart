import 'package:bakid/core/services/supabase_service.dart';
import 'package:bakid/features/auth/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider untuk Supabase client
final supabaseClientProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// Provider untuk auth controller
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
      final supabase = ref.watch(supabaseClientProvider);
      return AuthController(supabase);
    });
final authStateProvider = StreamProvider<User?>((ref) {
  final supabase = ref.read(supabaseClientProvider);
  return supabase.authStateChanges();
});
