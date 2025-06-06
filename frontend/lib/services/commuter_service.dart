import 'package:bussin_buses/services/supabase_client_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Booking.dart';

/// Simple API debouncer to prevent rapid successive calls
class ApiDebouncer {
  static final Map<String, DateTime> _lastCallTime = {};
  static final Duration _minInterval = Duration(seconds: 10);
  
  /// Checks if enough time has passed since the last API call with this key
  /// Returns true if the call should proceed, false if it should be skipped
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

/// Service for handling commuter-related API calls and data management
class CommuterService {
  final SupabaseClient _supabase = SupabaseClientService.client;
  
  // Constants for API endpoints
  static const String _host = "10.0.2.2:3000";
  static const String _basePath = "api";
  static const String _calculateEtaPath = "$_basePath/get-eta";
  
  /// Cache for ETAs to reduce API calls
  final Map<int, int> _etaCache = {};
  final Map<int, DateTime> _etaCacheTimestamp = {};
  final Duration _etaCacheValidity = Duration(minutes: 5); // Cache valid for 5 minutes
  
  /// Shared static ETA cache for use across ViewModels
  static final Map<int, int> sharedEtaCache = {};
  static final Map<int, DateTime> sharedEtaCacheTimestamp = {};
  static final Duration sharedEtaCacheValidity = Duration(minutes: 5);
  
  /// Gets an ETA from the shared cache
  /// Returns default value of 30 minutes if not found
  static int getSharedETA(int scheduleId) {
    return sharedEtaCache[scheduleId] ?? 30; // Default to 30 minutes if not found
  }
  
  /// Updates the shared ETA cache with a new value
  static void updateSharedETA(int scheduleId, int etaMinutes) {
    sharedEtaCache[scheduleId] = etaMinutes;
    sharedEtaCacheTimestamp[scheduleId] = DateTime.now();
  }
  
  /// Checks if a shared ETA cache entry is still valid
  static bool isSharedETAValid(int scheduleId) {
    final timestamp = sharedEtaCacheTimestamp[scheduleId];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < sharedEtaCacheValidity;
  }

  /// Fetches upcoming bookings for a commuter
  /// Filters out past bookings and caches ETAs
  Future<List<Booking>> fetchUpcomingBookings(String commuterId) async {
    final response = await _supabase
        .from('bookings')
        .select('booking_id, booking_date, is_checked_in, seat_id(seat_number), schedule_id(date, time, pickup(location_name), destination(location_name), bus_id(bus_number), eta)')
        .eq('commuter_id', commuterId);

    final List data = response as List;
    final now = DateTime.now();

    /// Process bookings and cache ETAs
    final bookings = data.where((bookingMap) {
      final schedule = bookingMap['schedule_id'];
      final dateStr = schedule?['date'];
      final timeStr = schedule?['time']?.toString();

      if (dateStr == null || timeStr == null || !timeStr.contains(':')) return false;

      try {
        /// Parse date and time to check if booking is in the future
        final date = DateTime.parse(dateStr);
        final parts = timeStr.split(':');
        final departure = DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
        return departure.isAfter(now);
      } catch (_) {
        return false;
      }
    }).map((b) {
      /// Cache ETA if available
      if (b['schedule_id'] != null && b['schedule_id']['eta'] != null) {
        final scheduleId = b['schedule_id']['schedule_id'] ?? 
                          int.tryParse(b['schedule_id'].toString().split('_').last) ?? 0;
        if (scheduleId > 0) {
          _etaCache[scheduleId] = b['schedule_id']['eta'];
          _etaCacheTimestamp[scheduleId] = DateTime.now();
          
          /// Update shared cache as well
          updateSharedETA(scheduleId, b['schedule_id']['eta']);
        }
      }
      return Booking.fromMap(b);
    }).toList();

    return bookings;
  }

  /// Cancels a booking by ID
  Future<void> cancelBooking(int bookingId) async {
    await _supabase.from('bookings').delete().eq('booking_id', bookingId);
  }

  /// Marks a booking as checked in
  Future<void> checkInBooking(dynamic bookingId) async {
    await _supabase
        .from('bookings')
        .update({'is_checked_in': true})
        .eq('booking_id', bookingId)
        .select();
  }

  /// Fetches details for a specific schedule
  /// Caches ETA if available
  Future<Map<String, dynamic>?> fetchScheduleDetails(int scheduleId) async {
    final data = await _supabase
        .from('schedules')
        .select('date, time, pickup(location_name), destination(location_name), bus_id(bus_number), eta, driver_id')
        .eq('schedule_id', scheduleId)
        .maybeSingle();
    
    /// Cache ETA if available
    if (data != null && data['eta'] != null) {
      _etaCache[scheduleId] = data['eta'];
      _etaCacheTimestamp[scheduleId] = DateTime.now();
      
      /// Update shared cache as well
      updateSharedETA(scheduleId, data['eta']);
    }
    
    return data;
  }

  /// Fetches booked seat numbers for a schedule
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

  /// Confirms a seat booking for a schedule
  /// Throws exception if seat is already booked or not found
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

    /// Check if seat is already booked for this schedule
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

    /// Create the booking
    await _supabase.from('bookings').insert({
      'commuter_id': commuterId,
      'schedule_id': scheduleId,
      'seat_id': seatId,
      'booking_date': DateTime.now().toIso8601String(),
    });

    print("[SUCCESS] Seat booked successfully.");
    return true;
  }

  /// Gets the current commuter ID from auth
  String? getCommuterId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Fetches location names and IDs
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

  /// Fetches all schedules with ETAs
  /// Caches ETAs from the response
  Future<List<Map<String, dynamic>>> fetchAllSchedules() async {
    try {
      final response = await _supabase
          .from('schedules')
          .select('*, eta')
          .order('time');
      
      /// Cache ETAs from the response
      for (var schedule in response) {
        if (schedule['schedule_id'] != null && schedule['eta'] != null) {
          _etaCache[schedule['schedule_id']] = schedule['eta'];
          _etaCacheTimestamp[schedule['schedule_id']] = DateTime.now();
          
          /// Update shared cache as well
          updateSharedETA(schedule['schedule_id'], schedule['eta']);
        }
      }
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching schedules: $e');
      return [];
    }
  }

  /// Fetches username for a user ID
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

  /// Adds minutes to a time string and returns the new time
  String addTimeToString(String timeStr, int minutes) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final time = DateTime(2025, 1, 1, hour, minute);
    final newTime = time.add(Duration(minutes: minutes));

    return '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}';
  }
  
  /// Calculates ETA for a schedule by calling the API
  /// Uses debouncing to prevent too many API calls
  Future<void> calculateETA(int scheduleId) async {
    /// Skip if we called this API recently for this schedule
    if (!ApiDebouncer.shouldProceed('eta_$scheduleId')) {
      print("Skipping ETA calculation - called too recently");
      return;
    }
    
    /// First get the driver_id for this schedule
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
        
        /// Try to parse the response to get the actual ETA
        try {
          final jsonResponse = jsonDecode(response.body);
          if (jsonResponse.containsKey('eta')) {
            _etaCache[scheduleId] = jsonResponse['eta'];
            _etaCacheTimestamp[scheduleId] = DateTime.now();
            
            /// Update shared cache as well
            updateSharedETA(scheduleId, jsonResponse['eta']);
          }
        } catch (e) {
          print("Error parsing ETA response: $e");
        }
      }
    } catch (e) {
      print("Error calling calculateETA: $e");
    }
  }
  
  /// Gets the current ETA for a schedule with caching
  /// Checks shared cache, local cache, and database
  /// Calculates a new ETA if needed
  Future<int> getScheduleETA(int scheduleId) async {
    /// First, check if we have a valid shared cached value
    if (isSharedETAValid(scheduleId)) {
      print("Using shared cached ETA for schedule $scheduleId: ${getSharedETA(scheduleId)} minutes");
      return getSharedETA(scheduleId);
    }
    
    /// Otherwise, check local cache
    final cachedTimestamp = _etaCacheTimestamp[scheduleId];
    if (cachedTimestamp != null && 
        DateTime.now().difference(cachedTimestamp) < _etaCacheValidity &&
        _etaCache.containsKey(scheduleId)) {
      /// Update shared cache with local cache
      updateSharedETA(scheduleId, _etaCache[scheduleId]!);
      print("Using local cached ETA for schedule $scheduleId: ${_etaCache[scheduleId]} minutes");
      return _etaCache[scheduleId]!;
    }
    
    try {
      final scheduleData = await _supabase
          .from('schedules')
          .select('eta')
          .eq('schedule_id', scheduleId)
          .maybeSingle();
      
      if (scheduleData != null && scheduleData['eta'] != null) {
        /// Cache the result in both local and shared cache
        _etaCache[scheduleId] = scheduleData['eta'];
        _etaCacheTimestamp[scheduleId] = DateTime.now();
        updateSharedETA(scheduleId, scheduleData['eta']);
        
        print("Retrieved ETA from database for schedule $scheduleId: ${scheduleData['eta']} minutes");
        return scheduleData['eta'];
      } else {
        /// Only calculate if we don't have a cached value
        if (!_etaCache.containsKey(scheduleId)) {
          print("No ETA found, attempting to calculate for schedule $scheduleId");
          await calculateETA(scheduleId);
          
          /// Try to get the updated ETA
          final updatedData = await _supabase
              .from('schedules')
              .select('eta')
              .eq('schedule_id', scheduleId)
              .maybeSingle();
              
          if (updatedData != null && updatedData['eta'] != null) {
            /// Cache the result in both local and shared cache
            _etaCache[scheduleId] = updatedData['eta'];
            _etaCacheTimestamp[scheduleId] = DateTime.now();
            updateSharedETA(scheduleId, updatedData['eta']);
            
            print("Calculated new ETA for schedule $scheduleId: ${updatedData['eta']} minutes");
            return updatedData['eta'];
          }
        }
      }
      
      /// Return shared cache value, local cached value, or default
      if (sharedEtaCache.containsKey(scheduleId)) {
        return sharedEtaCache[scheduleId]!;
      }
      
      final eta = _etaCache[scheduleId] ?? 30; // Default to 30 minutes
      updateSharedETA(scheduleId, eta);
      print("Using fallback ETA for schedule $scheduleId: $eta minutes");
      return eta;
    } catch (e) {
      print("Error getting schedule ETA: $e");
      
      /// Return shared cache value, local cached value, or default
      if (sharedEtaCache.containsKey(scheduleId)) {
        return sharedEtaCache[scheduleId]!;
      }
      
      final eta = _etaCache[scheduleId] ?? 30; // Default to 30 minutes
      updateSharedETA(scheduleId, eta);
      return eta;
    }
  }
}