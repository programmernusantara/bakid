import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';
import 'package:bakid/fitur/guru/profile/model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profilGuruProvider = FutureProvider<ProfilGuru?>((ref) async {
  final supabase = ref.read(supabaseProvider);
  final currentUser = ref.read(currentUserProvider);

  if (currentUser == null) return null;

  final userId = currentUser['id'];

  final response =
      await supabase
          .from('profil_guru')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

  if (response == null) return null;

  return ProfilGuru.fromMap(response);
});
