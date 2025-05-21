import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final pengumumanProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('pengumuman')
      .select()
      .eq('aktif', true)
      .order('dibuat_pada', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});
