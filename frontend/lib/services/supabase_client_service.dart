import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Expose the Supabase client
  static SupabaseClient get client => _supabase;
}