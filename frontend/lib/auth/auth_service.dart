import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService{
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

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

    final id = getCurrentUser();
    print("UserID: $id");

    await _supabase.from('profiles').update({'username': username, 'user_type': userType}).eq('id', uid);

    return response;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> forgetPassword(String email) async {
    return await _supabase.auth.resetPasswordForEmail(email);
  }

  String? getCurrentUser() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.id;
  }
}