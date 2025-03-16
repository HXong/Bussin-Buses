import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

Future<List<Map<String, dynamic>>> fetchPassengerDetails(String scheduleId) async {
  final bookingResponse = await Supabase.instance.client
      .from('bookings')
      .select('seat_id, commuter_id')
      .eq('schedule_id', scheduleId);

  List<Map<String, dynamic>> passengerDetails = [];

  for (var booking in bookingResponse) {
    final seatId = booking['seat_id'].toString();
    final seatResponse = await Supabase.instance.client
        .from('seats')
        .select('seat_number')
        .eq('seat_id', seatId)
        .single();

    final commuterId = booking['commuter_id'].toString();
    final commuterResponse = await Supabase.instance.client
        .from('profiles')
        .select('username')
        .eq('id', commuterId)
        .single();

    passengerDetails.add({
      'commuter_name': commuterResponse['username'].toString(),
      'seat_number': seatResponse['seat_number'].toString(),
    });
  }
  passengerDetails.sort((a, b) => int.parse(a['seat_number']).compareTo(int.parse(b['seat_number'])));
  return passengerDetails;
}
