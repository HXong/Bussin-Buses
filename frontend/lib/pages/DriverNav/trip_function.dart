import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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
  final response = await Supabase.instance.client
      .from('location')
      .select('location_name')
      .eq('location_id', locationId)
      .single();

  return response?['location_name'] ?? 'Unknown Location';
}

// Helper function to format date
String formatDate(String dateStr) {
  DateTime date = DateTime.parse(dateStr);
  return DateFormat('dd MMM').format(date).toUpperCase();
}