import 'package:bussin_buses/services/supabase_client_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService{
  final SupabaseClient _supabase = SupabaseClientService.client;

  /// Signs into Supabase Auth
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Signs up on Supabase Auth and Creates new entry in profiles table
  Future<AuthResponse> signUp(String email, String password, String username, String userType) async {
    final AuthResponse response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    final String? uid = response.user?.id;
    if (uid == null) throw Exception("User ID is null");
    await _supabase.auth.updateUser(UserAttributes(
      data: {'display_name': username}, // Updates the display name
    ));
    await _supabase.from('profiles').update({'username': username, 'user_type': userType}).eq('id', uid);

    return response;
  }

  /// signs out of Supabase Auth
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// get the current user signed into Supabase Auth
  User? getCurrentUser() {
    final session = _supabase.auth.currentSession;
    return session?.user;
  }

  /// find out whether user is commuter or driver
  Future<String?> getUserType(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('user_type')
          .eq('id', userId)
          .single();
      return response['user_type'] as String?;
    } catch (e) {
      print('Error getting user type: $e');
      return null;
    }
  }
}