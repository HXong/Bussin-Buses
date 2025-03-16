import 'package:bussin_buses/services/supabase_client_service.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverService {
  final SupabaseClient _supabase = SupabaseClientService.client;
  List<Map<String, dynamic>> passengerDetails = [];
  List<Map<String, dynamic>> upcomingTrips = [];

  Future<List<Map<String, dynamic>>> fetchPassengerDetails(String scheduleId) async {
    final bookingResponse = await _supabase
        .from('bookings')
        .select('seat_id, commuter_id')
        .eq('schedule_id', scheduleId);

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

  Future<void> deleteTrip(Map<String, dynamic> trip) async {
    await Supabase.instance.client
        .from('schedules')
        .update({'delete_schedule': true})
        .eq('schedule_id', trip['schedule_id']);
  }

  // Function to fetch trips based on the boolean condition (before or after today)
  Future<List<Map<String, dynamic>>> fetchTrips(String driverId, DateTime targetDate, bool fetchBefore, bool onlyConfirmed) async {
    final response = await Supabase.instance.client
        .from('schedules')
        .select()
        .eq('driver_id', driverId)
        .order('date', ascending: true);

    List<Map<String, dynamic>> tripsWithLocations = [];

    for (var trip in response) {
      String pickupName = await getLocationName(trip['pickup']);
      String destinationName = await getLocationName(trip['destination']);

      String dateStr = trip['date']; // YYYY-MM-DD
      String timeStr = trip['time']; // HH:MM:SS
      String formattedDate = formatDate(dateStr);

      DateTime startTime = DateTime.parse('$dateStr $timeStr');
      DateTime endTime = startTime.add(const Duration(minutes: 75));
      String endTimeFormatted = endTime.toIso8601String().substring(11, 16);

      DateTime tripDate = DateTime.parse(dateStr);

      // Determine if we should include the trip based on the boolean condition
      bool includeTrip = false;
      String status = "CONFIRMED";
      targetDate = DateTime.now();
      if (fetchBefore && tripDate.isBefore(targetDate)) {
        includeTrip = true;
        {
          if (trip['delete_schedule'])
          {
            status = "CANCELLED";
          }
          else
          {
            status = "COMPLETED";
          }
        }
      } else if (!fetchBefore && tripDate.isAfter(targetDate)) {
        includeTrip = true;
        {
          if (trip['delete_schedule'])
          {
            status = "CANCELLED";
          }
          else
          {
            status = "CONFIRMED";
          }
        }
      }

      if (onlyConfirmed && trip['delete_schedule'] == true) {
        includeTrip = false;
      }

      if (includeTrip) {
        tripsWithLocations.add({
          'schedule_id': trip['schedule_id'],
          'date': formattedDate,
          'start_time': timeStr.substring(0, 5),
          'end_time': endTimeFormatted,
          'duration': '1h 15min',
          'pickup': pickupName,
          'destination': destinationName,
          'status' : status,
        });
      }
    }

    return tripsWithLocations;
  }

// Helper function to fetch location name
  Future<String> getLocationName(int locationId) async {
    final response = await _supabase
        .from('location')
        .select('location_name')
        .eq('location_id', locationId)
        .single();

    return response['location_name'] ?? 'Unknown Location';
  }

// Helper function to format date
  String formatDate(String dateStr) {
    DateTime date = DateTime.parse(dateStr);
    return DateFormat('dd MMM').format(date).toUpperCase();
  }

  // Fetch past trips for the current driver from Supabase
  Future<List<Map<String,dynamic>>> fetchPastTrips(DateTime targetDate) async {
    final driverId = _supabase.auth.currentUser!.id;

    // Use the imported function to fetch past trips
    return await fetchTrips(driverId, targetDate, true, false);


  }
}

