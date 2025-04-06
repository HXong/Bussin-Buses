import 'package:bussin_buses/services/supabase_client_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Booking.dart';

// Simple API debouncer to prevent rapid successive calls
class ApiDebouncer {
  static final Map<String, DateTime> _lastCallTime = {};
  static final Duration _minInterval = Duration(seconds: 10);
  
  static bool shouldProceed(String key) {
    final now = DateTime.now();
    final lastTime = _lastCallTime[key];
    
    if (lastTime == null || now.difference(lastTime) > _minInterval) {
      _lastCallTime[key] = now;
      return true;
    }
    
    return false;
  }
}

class CommuterService {
  final SupabaseClient _supabase = SupabaseClientService.client;
  
  // Constants for API endpoints
  static const String _host = "10.0.2.2:3000";
  static const String _basePath = "api";
  static const String _calculateEtaPath = "$_basePath/get-eta";
  
  // Cache for ETAs to reduce API calls
  final Map<int, int> _etaCache = {};
  final Map<int, DateTime> _etaCacheTimestamp = {};
  final Duration _etaCacheValidity = Duration(minutes: 5); // Cache valid for 5 minutes

  Future<List<Booking>> fetchUpcomingBookings(String commuterId) async {
    final response = await _supabase
        .from('bookings')
        .select('booking_id, booking_date, is_checked_in, seat_id(seat_number), schedule_id(date, time, pickup(location_name), destination(location_name), bus_id(bus_number), eta)')
        .eq('commuter_id', commuterId);

    final List data = response as List;
    final now = DateTime.now();

    // Process bookings and cache ETAs
    final bookings = data.where((bookingMap) {
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
    }).map((b) {
      // Cache ETA if available
      if (b['schedule_id'] != null && b['schedule_id']['eta'] != null) {
        final scheduleId = b['schedule_id']['schedule_id'] ?? 
                          int.tryParse(b['schedule_id'].toString().split('_').last) ?? 0;
        if (scheduleId > 0) {
          _etaCache[scheduleId] = b['schedule_id']['eta'];
          _etaCacheTimestamp[scheduleId] = DateTime.now();
        }
      }
      return Booking.fromMap(b);
    }).toList();

    return bookings;
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
    final data = await _supabase
        .from('schedules')
        .select('date, time, pickup(location_name), destination(location_name), bus_id(bus_number), eta, driver_id')
        .eq('schedule_id', scheduleId)
        .maybeSingle();
    
    // Cache ETA if available
    if (data != null && data['eta'] != null) {
      _etaCache[scheduleId] = data['eta'];
      _etaCacheTimestamp[scheduleId] = DateTime.now();
    }
    
    return data;
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
    print("[DEBUG] Trying to book seatNumber: $seatNumber for scheduleId: $scheduleId");

    final seatData = await _supabase
        .from('seats')
        .select('seat_id')
        .eq('seat_number', seatNumber)
        .limit(1)
        .maybeSingle();

    print("[DEBUG] seatData fetched: $seatData");

    final seatId = seatData?['seat_id'];
    if (seatId == null) {
      print("[ERROR] Seat ID is NULL. Seat number not found in seats table.");
      throw Exception("Seat not found");
    }

    final alreadyBooked = await _supabase
        .from('bookings')
        .select('seat_id')
        .eq('schedule_id', scheduleId)
        .eq('seat_id', seatId)
        .maybeSingle();

    if (alreadyBooked != null) {
      print("[ERROR] Seat already booked for this schedule.");
      throw Exception("Seat already booked");
    }

    await _supabase.from('bookings').insert({
      'commuter_id': commuterId,
      'schedule_id': scheduleId,
      'seat_id': seatId,
      'booking_date': DateTime.now().toIso8601String(),
    });

    print("[SUCCESS] Seat booked successfully.");
    return true;
  }

  String? getCommuterId() {
    return _supabase.auth.currentUser?.id;
  }

  Future<Map<int, String>> fetchLocationNames() async {
    try {
      final response = await _supabase
          .from('location')
          .select('location_id, location_name');

      Map<int, String> locationNames = {};
      for (var location in response) {
        locationNames[location['location_id']] = location['location_name'];
      }
      return locationNames;
    } catch (e) {
      print('Error fetching locations: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllSchedules() async {
    try {
      final response = await _supabase
          .from('schedules')
          .select('*, eta')
          .order('time');
      
      // Cache ETAs from the response
      for (var schedule in response) {
        if (schedule['schedule_id'] != null && schedule['eta'] != null) {
          _etaCache[schedule['schedule_id']] = schedule['eta'];
          _etaCacheTimestamp[schedule['schedule_id']] = DateTime.now();
        }
      }
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching schedules: $e');
      return [];
    }
  }

  // New methods for HomeNav
  Future<String?> fetchUsername(String userId) async {
    try {
      final userData = await _supabase
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .single();

      return userData['username'] as String?;
    } catch (e) {
      print('Error loading user data: $e');
      return null;
    }
  }

  String addTimeToString(String timeStr, int minutes) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final time = DateTime(2025, 1, 1, hour, minute);
    final newTime = time.add(Duration(minutes: minutes));

    return '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}';
  }
  
  // New method to calculate ETA with debouncing and error handling
  Future<void> calculateETA(int scheduleId) async {
    // Skip if we called this API recently for this schedule
    if (!ApiDebouncer.shouldProceed('eta_$scheduleId')) {
      print("Skipping ETA calculation - called too recently");
      return;
    }
    
    // First get the driver_id for this schedule
    final scheduleData = await _supabase
        .from('schedules')
        .select('driver_id')
        .eq('schedule_id', scheduleId)
        .maybeSingle();
    
    if (scheduleData == null || scheduleData['driver_id'] == null) {
      print("No driver assigned to schedule $scheduleId, can't calculate ETA");
      return; // No driver assigned, can't calculate ETA
    }
    
    final driverId = scheduleData['driver_id'];
    
    Uri url = Uri.http(_host, _calculateEtaPath);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driver_id': driverId,
          'schedule_id': scheduleId.toString(),
        }),
      );

      if (response.statusCode != 200) {
        print("Failed to calculate ETA. Status: ${response.statusCode}, Body: ${response.body}");
      } else {
        print("ETA calculated and stored successfully.");
        
        // Try to parse the response to get the actual ETA
        try {
          final jsonResponse = jsonDecode(response.body);
          if (jsonResponse.containsKey('eta')) {
            _etaCache[scheduleId] = jsonResponse['eta'];
            _etaCacheTimestamp[scheduleId] = DateTime.now();
          }
        } catch (e) {
          print("Error parsing ETA response: $e");
        }
      }
    } catch (e) {
      print("Error calling calculateETA: $e");
    }
  }
  
  // Get the current ETA for a schedule with caching
  Future<int> getScheduleETA(int scheduleId) async {
    // Check if we have a valid cached value
    final cachedTimestamp = _etaCacheTimestamp[scheduleId];
    if (cachedTimestamp != null && 
        DateTime.now().difference(cachedTimestamp) < _etaCacheValidity &&
        _etaCache.containsKey(scheduleId)) {
      print("Using cached ETA for schedule $scheduleId: ${_etaCache[scheduleId]} minutes");
      return _etaCache[scheduleId]!;
    }
    
    try {
      final scheduleData = await _supabase
          .from('schedules')
          .select('eta')
          .eq('schedule_id', scheduleId)
          .maybeSingle();
      
      if (scheduleData != null && scheduleData['eta'] != null) {
        // Cache the result
        _etaCache[scheduleId] = scheduleData['eta'];
        _etaCacheTimestamp[scheduleId] = DateTime.now();
        print("Retrieved ETA from database for schedule $scheduleId: ${scheduleData['eta']} minutes");
        return scheduleData['eta'];
      } else {
        // Only calculate if we don't have a cached value
        if (!_etaCache.containsKey(scheduleId)) {
          print("No ETA found, attempting to calculate for schedule $scheduleId");
          await calculateETA(scheduleId);
          
          // Try to get the updated ETA
          final updatedData = await _supabase
              .from('schedules')
              .select('eta')
              .eq('schedule_id', scheduleId)
              .maybeSingle();
              
          if (updatedData != null && updatedData['eta'] != null) {
            // Cache the result
            _etaCache[scheduleId] = updatedData['eta'];
            _etaCacheTimestamp[scheduleId] = DateTime.now();
            print("Calculated new ETA for schedule $scheduleId: ${updatedData['eta']} minutes");
            return updatedData['eta'];
          }
        }
      }
      
      // Return cached value or default
      final eta = _etaCache[scheduleId] ?? 75;
      print("Using fallback ETA for schedule $scheduleId: $eta minutes");
      return eta;
    } catch (e) {
      print("Error getting schedule ETA: $e");
      return _etaCache[scheduleId] ?? 75; // Return cached or default ETA
    }
  }
}