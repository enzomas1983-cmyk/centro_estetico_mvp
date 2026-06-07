import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  Future<List<dynamic>> getServices() async {
    final data = await supabase
        .from('services')
        .select();

    return data;
  }
}