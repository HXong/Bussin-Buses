import 'package:bussin_buses/services/supabase_client_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/Booking.dart';

class CommuterService {
  final SupabaseClient _supabase = SupabaseClientService.client;

  Future<List<Booking>> fetchUpcomingBookings(String commuterId) async {
    final response = await _supabase
        .from('bookings')
        .select('booking_id, booking_date, is_checked_in, seat_id(seat_number), schedule_id(date, time, pickup(location_name), destination(location_name))')
        .eq('commuter_id', commuterId);

    final List data = response as List;
    final now = DateTime.now();

    return data.where((bookingMap) {
      final schedule = bookingMap['schedule_id'];
      final dateStr = schedule?['date'];
      final timeStr = schedule?['time']?.toString();

      if (dateStr == null || timeStr == null || !timeStr.contains(':')) return false;

      try {
        final date = DateTime.parse(dateStr);
        final parts = timeStr.split(':');
        final departure = DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
        return departure.isAfter(now);
      } catch (_) {
        return false;
      }
    }).map((b) => Booking.fromMap(b)).toList();
  }



  Future<void> cancelBooking(int bookingId) async {
    await _supabase.from('bookings').delete().eq('booking_id', bookingId);
  }

  Future<void> checkInBooking(dynamic bookingId) async {
    await _supabase
        .from('bookings')
        .update({'is_checked_in': true})
        .eq('booking_id', bookingId)
        .select();
  }

  Future<Map<String, dynamic>?> fetchScheduleDetails(int scheduleId) async {
    return await _supabase
        .from('schedules')
        .select('date, time, pickup(location_name), destination(location_name)')
        .eq('schedule_id', scheduleId)
        .maybeSingle();
  }

  Future<List<String>> fetchBookedSeatNumbers(int scheduleId) async {
    final seatIds = await _supabase
        .from('bookings')
        .select('seat_id')
        .eq('schedule_id', scheduleId);

    final List<String> booked = [];
    for (var seat in seatIds) {
      final seatId = seat['seat_id'];
      final seatInfo = await _supabase
          .from('seats')
          .select('seat_number')
          .eq('seat_id', seatId)
          .maybeSingle();
      if (seatInfo != null && seatInfo['seat_number'] != null) {
        booked.add(seatInfo['seat_number'].toString());
      }
    }
    return booked;
  }

  Future<bool> confirmSeatBooking({
    required String commuterId,
    required int scheduleId,
    required int seatNumber,
  }) async {
    final seatData = await _supabase
        .from('seats')
        .select('seat_id')
        .eq('seat_number', seatNumber)
        .maybeSingle();

    final seatId = seatData?['seat_id'];
    if (seatId == null) throw Exception("Seat not found");

    final alreadyBooked = await _supabase
        .from('bookings')
        .select('seat_id')
        .eq('schedule_id', scheduleId)
        .eq('seat_id', seatId)
        .maybeSingle();

    if (alreadyBooked != null) throw Exception("Seat already booked");

    await _supabase.from('bookings').insert({
      'commuter_id': commuterId,
      'schedule_id': scheduleId,
      'seat_id': seatId,
      'booking_date': DateTime.now().toIso8601String(),
    });

    return true;
  }

  String? getCommuterId() {
    return _supabase.auth.currentUser?.id;
  }

}
