import 'package:supabase_flutter/supabase_flutter.dart';

/// singleton instance of SupabaseClient
class SupabaseClientService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Expose the Supabase client
  static SupabaseClient get client => _supabase;
}