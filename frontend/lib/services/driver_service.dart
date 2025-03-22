import 'package:bussin_buses/services/supabase_client_service.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverService {
  final SupabaseClient _supabase = SupabaseClientService.client;
  List<Map<String, dynamic>> passengerDetails = [];

  //Function to fetch passenger details for corresponding schedule
  Future<List<Map<String, dynamic>>> fetchPassengerDetails(String scheduleId) async {
    final bookingResponse = await _supabase
        .from('bookings')
        .select('seat_id, commuter_id')
        .eq('schedule_id', scheduleId);

    for (var booking in bookingResponse) {
      final seatId = booking['seat_id'].toString();
      final seatResponse = await _supabase
          .from('seats')
          .select('seat_number')
          .eq('seat_id', seatId)
          .single();

      final commuterId = booking['commuter_id'].toString();
      final commuterResponse = await _supabase
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

  //Function to delete a schedule
  Future<void> deleteTrip(Map<String, dynamic> trip) async {
    await _supabase
        .from('schedules')
        .update({'delete_schedule': true})
        .eq('schedule_id', trip['schedule_id']);
  }

  // Function to fetch trips based on the boolean condition (before or after today)
  Future<List<Map<String, dynamic>>> fetchTrips(String driverId, DateTime targetDate, bool fetchBefore, bool onlyConfirmed) async {
    var baseQuery = _supabase
        .from('schedules')
        .select();

    if (driverId.isNotEmpty) {
      var driverQuery = baseQuery.eq('driver_id', driverId);
      baseQuery = driverQuery;
    }
    var orderedQuery = baseQuery.order('date', ascending: true);
    final response = await orderedQuery;

    List<Map<String, dynamic>> tripsWithLocations = [];

    for (var trip in response) {
      String pickupName = await getLocationName(trip['pickup']);
      String destinationName = await getLocationName(trip['destination']);

      String dateStr = trip['date']; // YYYY-MM-DD
      String timeStr = trip['time']; // HH:MM:SS
      DateTime startTime = DateTime.parse('$dateStr $timeStr');
      DateTime endTime = startTime.add(const Duration(minutes: 75));
      String formattedDate = formatDate(dateStr);
      String endTimeFormatted = DateFormat('HH:mm').format(endTime);
      DateTime tripDate = DateTime.parse(dateStr);

      String driverName = '';
      if (trip['driver_id'] != null) {
        final driverProfile = await _supabase
            .from('profiles')
            .select('username')
            .eq('id', trip['driver_id'])
            .single();

        driverName = driverProfile['username'] ?? 'Unknown Driver';
      }

      // Determine if we should include the trip based on the boolean condition
      bool includeTrip = false;
      String status = "CONFIRMED";
      if (fetchBefore && tripDate.isBefore(targetDate)) {
        includeTrip = true;
        status = trip['delete_schedule'] ? "CANCELLED" : "COMPLETED";
      } else if (!fetchBefore && tripDate.isAfter(targetDate)) {
        includeTrip = true;
        status = trip['delete_schedule'] ? "CANCELLED" : "CONFIRMED";
      }

      if (onlyConfirmed && trip['delete_schedule'] == true) {
        includeTrip = false;
      }

      if (includeTrip) {
        tripsWithLocations.add({
          'schedule_id': trip['schedule_id'],
          'driver_name': driverName,
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

  String formatDate(String dateStr) {
    DateTime date = DateTime.parse(dateStr);
    return DateFormat('dd MMM').format(date).toUpperCase();
  }

  //Function to fetch past trips for the current driver from Supabase
  Future<List<Map<String,dynamic>>> fetchPastTrips(DateTime targetDate) async {
    final driverId = _supabase.auth.currentUser!.id;

    // Use the imported function to fetch past trips
    return await fetchTrips(driverId, targetDate, true, false);
  }

  Future<List<String>> fetchLocations() async {
    try {
      final response = await _supabase.from('location').select('location_name');
      return response.map<String>((row) => row['location_name'] as String).toList();
    } catch (e) {
      throw Exception("Error fetching locations: $e");
    }
  }

  Future<int> getLocationIdByName(String locationName) async {
    final response = await _supabase
        .from('location')
        .select('location_id')
        .eq('location_name', locationName)
        .single();
    return response['location_id'];
  }

  // Add a new journey to the database
  Future<void> addJourney({
    required int pickupId,
    required int destinationId,
    required String date,
    required String time,
    required String driverId,
  }) async {
    final response = await _supabase.from('schedules').insert([
      {
        'pickup': pickupId,
        'destination': destinationId,
        'date': date,
        'time': time,
        'driver_id': driverId,
      }
    ]).select();

    if (response.isEmpty) {
      throw Exception("No data returned, journey not added");
    }
  }

  Future<Map<String, String>> fetchDriverProfile(String driverId) async {
    final driverProfile = await _supabase
        .from('profiles')
        .select('username, user_type, created_at')
        .eq('id', driverId)
        .single();

    DateTime dateTime = DateTime.parse(driverProfile['created_at']);
    String date = DateFormat('dd MMM yyyy').format(dateTime);

    return {
      'username': driverProfile['username'] ?? 'unknown',
      'user_type': driverProfile['user_type'] ?? 'unknown',
      'created_at': date ?? 'unknown',
    };
  }

  Future<String> fetchBusPlate(String driverId) async {
    final busPlate = await _supabase
        .from('buses')
        .select('bus_number')
        .eq('driver_id', driverId)
        .single();

    return busPlate['bus_number'] ?? 'unknown';
  }

  Future<void> storeFeedback(String feedback, String userId) async {
    try {
      await _supabase.from('feedback').insert({'feedback': feedback, 'user_id': userId});
    } catch (e) {
      throw Exception("Error submitting feedback: $e");
    }
  }
}

