import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bakid/app/app_providers.dart';

final pengumumanControllerProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final supabase = ref.watch(supabaseClientProvider);
      return supabase.getPengumumanStream();
    });
