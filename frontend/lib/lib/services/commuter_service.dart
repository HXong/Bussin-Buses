import 'package:supabase_flutter/supabase_flutter.dart';

abstract class CommuterService {
  // User profile methods
  Future<Map<String, dynamic>> getUserProfile();
  Future<void> updateUserProfile({
    required String fullName,
    required String phone,
    String? profilePicture,
  });
  Future<void> signOut();

  // Bus search and booking methods
  Future<List<Map<String, dynamic>>> searchBuses({
    required String from,
    required String to,
    required DateTime date,
  });
  Future<Map<String, dynamic>> getBusDetails(String busId);
  Future<Map<String, dynamic>> bookBus({
    required String busId,
    required String seatNumber,
    required String passengerName,
    required String passengerEmail,
    required String passengerPhone,
  });

  // Booking management methods
  Future<List<Map<String, dynamic>>> getUpcomingBookings();
  Future<Map<String, dynamic>> getBookingDetails(String bookingId);
  Future<bool> cancelBooking(String bookingId);
  Future<void> checkInBooking(String bookingId);
}

class SupabaseCommuterService implements CommuterService {
  final SupabaseClient _supabaseClient;

  SupabaseCommuterService(this._supabaseClient);

  @override
  Future<Map<String, dynamic>> getUserProfile() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabaseClient
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return response;
  }

  @override
  Future<void> updateUserProfile({
    required String fullName,
    required String phone,
    String? profilePicture,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final updates = {
      'full_name': fullName,
      'phone': phone,
      if (profilePicture != null) 'avatar_url': profilePicture,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _supabaseClient.from('profiles').update(updates).eq('id', user.id);
  }

  @override
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  @override
  Future<List<Map<String, dynamic>>> searchBuses({
    required String from,
    required String to,
    required DateTime date,
  }) async {
    final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final response = await _supabaseClient
        .from('buses')
        .select()
        .eq('from_location', from)
        .eq('to_location', to)
        .eq('date', formattedDate)
        .order('departure_time');

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<Map<String, dynamic>> getBusDetails(String busId) async {
    final response = await _supabaseClient
        .from('buses')
        .select('*, bus_companies(*)')
        .eq('id', busId)
        .single();

    return response;
  }

  @override
  Future<Map<String, dynamic>> bookBus({
    required String busId,
    required String seatNumber,
    required String passengerName,
    required String passengerEmail,
    required String passengerPhone,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get bus details for price
    final busDetails = await getBusDetails(busId);

    final bookingData = {
      'user_id': user.id,
      'bus_id': busId,
      'seat_number': seatNumber,
      'passenger_name': passengerName,
      'passenger_email': passengerEmail,
      'passenger_phone': passengerPhone,
      'status': 'confirmed',
      'price': busDetails['price'],
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabaseClient
        .from('bookings')
        .insert(bookingData)
        .select()
        .single();

    // Update seat availability
    await _supabaseClient.rpc(
      'decrease_available_seats',
      params: {'bus_id': busId},
    );

    return response;
  }

  @override
  Future<List<Map<String, dynamic>>> getUpcomingBookings() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabaseClient
        .from('bookings')
        .select('*, buses(*)')
        .eq('user_id', user.id)
        .neq('status', 'cancelled')
        .gte('buses.date', DateTime.now().toIso8601String().split('T')[0])
        .order('buses.date');

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<Map<String, dynamic>> getBookingDetails(String bookingId) async {
    final response = await _supabaseClient
        .from('bookings')
        .select('*, buses(*)')
        .eq('id', bookingId)
        .single();

    return response;
  }

  @override
  Future<bool> cancelBooking(String bookingId) async {
    try {
      // Get booking details to get the bus_id
      final booking = await getBookingDetails(bookingId);
      final busId = booking['bus_id'];

      // Update booking status
      await _supabaseClient
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);

      // Increase available seats
      await _supabaseClient.rpc(
        'increase_available_seats',
        params: {'bus_id': busId},
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> checkInBooking(String bookingId) async {
    await _supabaseClient
        .from('bookings')
        .update({'status': 'checked_in'})
        .eq('id', bookingId);
  }
}

