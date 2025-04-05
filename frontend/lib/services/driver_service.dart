import 'dart:async';
import 'package:bussin_buses/models/Passengers.dart';
import 'package:bussin_buses/models/Trips.dart';
import 'package:bussin_buses/services/supabase_client_service.dart';
import 'package:bussin_buses/services/route_service.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverService {
  final SupabaseClient _supabase = SupabaseClientService.client;
  List<Map<String, dynamic>> passengerDetails = [];
  final _notificationController = StreamController<Map<String, dynamic>>();
  RealtimeChannel? _notificationChannel;
  Stream<Map<String, dynamic>> get updates => _notificationController.stream.asBroadcastStream();
  final RouteService _routeService = RouteService();

  //Function to fetch passenger details for corresponding schedule
  Future<List<Passenger>> fetchPassengerDetails(String scheduleId) async {
    List<Passenger> passengers = [];

    final bookingResponse = await _supabase
        .from('bookings')
        .select('seat_id, commuter_id, is_checked_in')
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

      final checkInStatus = booking['is_checked_in'];

      passengers.add(
        Passenger(
          id: commuterId,
          name: commuterResponse['username'].toString(),
          email: "",  // If email is available, fetch it
          phone: "",  // If phone is available, fetch it
          seatNumber: seatResponse['seat_number'].toString(),
          isCheckedIn: checkInStatus,
        ),
      );
    }

    // Sort by seat number
    passengers.sort((a, b) => int.parse(a.seatNumber).compareTo(int.parse(b.seatNumber)));

    return passengers;
  }

  Future<bool> checkJourneyStarted(int scheduleId) async {
    final journeyStartedResponse = await _supabase
      .from('journey')
      .select('journey_started')
      .eq('schedule_id', scheduleId)
      .maybeSingle();
    if (journeyStartedResponse == null) {
      return false;
    }
    return journeyStartedResponse['journey_started'] as bool;
  }

  //Function to delete a schedule
  Future<void> deleteTrip(Trip trip) async {
    await _supabase
        .from('schedules')
        .update({'delete_schedule': true})
        .eq('schedule_id', trip.scheduleId);
  }

  // Function to fetch trips based on the boolean condition (before or after today)
  Future<List<Trip>> fetchTrips(String driverId, DateTime targetDate, bool fetchBefore, bool onlyConfirmed) async {
    var baseQuery = _supabase.from('schedules').select();

    if (driverId.isNotEmpty) {
      baseQuery = baseQuery.eq('driver_id', driverId);
    }

    var orderedQuery = baseQuery.order('date', ascending: true);
    final response = await orderedQuery;

    List<Trip> tripsWithLocations = [];

    for (var trip in response) {
      String pickupName = await getLocationName(trip['pickup']);
      String destinationName = await getLocationName(trip['destination']);
      String dateStr = trip['date']; // YYYY-MM-DD
      String timeStr = trip['time']; // HH:MM:SS
      int duration = trip['eta'] ?? 75;
      DateTime startDateTime = DateTime.parse('$dateStr $timeStr');
      DateTime endStartDateTime = startDateTime.add(Duration(minutes: duration));
      String formattedDate = formatDate(dateStr);
      String formattedEndTime = DateFormat('HH:mm').format(endStartDateTime);

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
      bool isJourneyStarted = await checkJourneyStarted(trip['schedule_id']);
      String status = "CONFIRMED";

      if (fetchBefore && startDateTime.isBefore(targetDate)) {
        includeTrip = true;
        status = trip['delete_schedule'] ? "CANCELLED" : "COMPLETED";
      } else if (!fetchBefore && startDateTime.isAfter(targetDate)) {
        includeTrip = true;
        status = trip['delete_schedule'] ? "CANCELLED" : "CONFIRMED";
      }
      if (isJourneyStarted) {
        status = "IN PROGRESS";
      }
      if (onlyConfirmed && trip['delete_schedule'] == true) {
        includeTrip = false;
      }

      if (includeTrip) {
        tripsWithLocations.add(Trip(
          scheduleId: trip['schedule_id'].toString(),
          driverName: driverName,
          date: formattedDate,
          startTime: timeStr.substring(0, 5),
          endTime: formattedEndTime,
          duration: "$duration mins",
          pickup: pickupName,
          destination: destinationName,
          status: status,
          isJourneyStarted: isJourneyStarted,
        ));
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

    final scheduleId = response.first['schedule_id'];
    
    try {
      await _routeService.calculateETA(driverId, scheduleId.toString());
    } catch (e) {
      print("Error calling calculateETA: $e");
    }
  }

  Future<Map<String, dynamic>> fetchDriverProfile(String driverId) async {
    try {
      final driverProfile = await _supabase
          .from('profiles')
          .select('username, user_type, created_at')
          .eq('id', driverId)
          .single();
      return driverProfile;

    } catch (e) {
      print('Error fetching driver profile: $e');
      return {};
    }
  }

  Future<void> storeFeedback(String feedback, String userId) async {
    try {
      await _supabase.from('feedback').insert({'feedback': feedback, 'user_id': userId});
    } catch (e) {
      throw Exception("Error submitting feedback: $e");
    }
  }

  Future<void> updateDriverLocation(String driverId, double lat, double lng) async {
    final res = await _supabase.from("driver_location")
        .upsert({
      "driver_id": _supabase.auth.currentUser!.id,
      "latitude": lat,
      "longitude": lng,
      "last_update": DateTime.now().toUtc().toIso8601String()
    }, onConflict: "driver_id");

  }

  void subscribeToNotifications() {
    if (_notificationChannel != null) return;

    _notificationChannel = _supabase
    .channel('notifications')
    .onPostgresChanges(event: PostgresChangeEvent.insert, schema: "public", table: "notifications",callback: (payload) {
      print("NEW PAYLOAD");
      print(payload.toString());
      final newRecord = payload.newRecord;
      if (newRecord["driver_id"] == _supabase.auth.currentUser!.id) {
        _notificationController.add(newRecord);
      }
    });

    _notificationChannel?.subscribe();
  }

  void unsubscribeToNotifications() {
    if (_notificationChannel != null) {
      _supabase.removeChannel(_notificationChannel!);
      _notificationChannel = null;
    }
  }

  void dispose() {
    _notificationController.close();
    _supabase.removeAllChannels();
  }


}

