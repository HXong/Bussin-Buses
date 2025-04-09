// lib/services/account_service.dart
import 'package:bussin_buses/services/supabase_client_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountService {
  final SupabaseClient _supabase = SupabaseClientService.client;

  /// Get user profile information
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      // Return empty map on error
      return {};
    }
  }
  
  /// Update user profile
  Future<bool> updateUserProfile({
    required String fullName,
    required String phone,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('profiles')
          .update({
            'username': fullName,
            'phone': phone,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
  
  /// Change password
  Future<bool> changePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
      return true;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }
}