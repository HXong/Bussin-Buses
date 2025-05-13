import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton class to manage seat booking state
class SeatManager {
  /// Singleton instance
  static final SeatManager _instance = SeatManager._internal();
  factory SeatManager() => _instance;

  SeatManager._internal();

  List<String> bookedSeats = []; // List to store booked seats
  
  /// Loads booked seats from database
  Future<void> loadBookedSeats() async {
    final response = await Supabase.instance.client
        .from('bookings')
        .select('seat_id');
    bookedSeats = List<String>.from(response.map((row) => row['seat_id'].toString()));
  }
}

/// Global instance of seat manager
final seatManager = SeatManager();