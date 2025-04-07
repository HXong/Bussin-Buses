// lib/services/live_location_service.dart
import 'package:bussin_buses/services/supabase_client_service.dart';
import 'package:bussin_buses/services/commuter_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';

class LiveLocationService {
  final SupabaseClient _supabase = SupabaseClientService.client;
  final CommuterService _commuterService = CommuterService();

  // Get the current location of a bus for a specific booking
  Future<Map<String, dynamic>> getBusLiveLocation(int bookingId) async {
    try {
      // First, get the schedule_id from the booking
      final bookingData = await _supabase
          .from('bookings')
          .select('schedule_id')
          .eq('booking_id', bookingId)
          .single();
      
      final scheduleId = bookingData['schedule_id'];
      
      // Then get the driver_id from the schedule
      final scheduleData = await _supabase
          .from('schedules')
          .select('driver_id, pickup(location_name), destination(location_name), date, time, eta')
          .eq('schedule_id', scheduleId)
          .single();
      
      final driverId = scheduleData['driver_id'];
      final pickupName = scheduleData['pickup']['location_name'];
      final destinationName = scheduleData['destination']['location_name'];
      final date = scheduleData['date'];
      final time = scheduleData['time'];
      
      // Get the driver's current location
      final locationData = await _supabase
          .from('driver_location')
          .select('latitude, longitude, last_update')
          .eq('driver_id', driverId)
          .maybeSingle();
      
      // Get the ETA from the shared cache or calculate it if needed
      int eta = 30; // Default to 30 minutes

      // First check if we have a valid value in the shared cache
      if (CommuterService.isSharedETAValid(scheduleId)) {
        eta = CommuterService.getSharedETA(scheduleId);
      } else {
        // Try to get a fresh ETA calculation
        try {
          await _commuterService.calculateETA(scheduleId);
          eta = await _commuterService.getScheduleETA(scheduleId);
        } catch (e) {
          print('Error calculating ETA: $e');
          
          // If calculation fails, try to get the stored ETA
          if (scheduleData['eta'] != null) {
            eta = scheduleData['eta'];
            CommuterService.updateSharedETA(scheduleId, eta);
          }
        }
      }
      
      // For demo purposes, calculate a mock progress based on time
      final departureTime = DateTime.parse('${scheduleData['date']} ${scheduleData['time']}');
      final now = DateTime.now();
      final totalJourneyTime = Duration(minutes: eta); // Use the actual ETA
      
      double progress = 0.0;
      if (now.isAfter(departureTime)) {
        final elapsed = now.difference(departureTime);
        progress = elapsed.inMinutes / totalJourneyTime.inMinutes;
        if (progress > 1.0) progress = 1.0;
      }
      
      // Generate stops based on the route
      final stops = _generateStops(pickupName, destinationName, time, progress, eta);
      
      // Calculate ETA
      final etaTime = _addMinutesToTime(
        time.toString(), 
        eta - (eta * progress).round()
      );
      
      // Determine current location name based on progress
      String currentLocation = _determineCurrentLocation(stops, progress);
      
      // Get bus number based on the route
      String busNumber = _getBusNumber(pickupName, destinationName);
      
      return {
        'current_location': currentLocation,
        'destination': destinationName,
        'eta': etaTime,
        'current_time': DateTime.now().hour.toString().padLeft(2, '0') + ':' + 
                      DateTime.now().minute.toString().padLeft(2, '0'),
        'progress': progress,
        'stops': stops,
        'latitude': locationData?['latitude'] ?? 1.3521,
        'longitude': locationData?['longitude'] ?? 103.8198,
        'last_update': locationData?['last_update'] ?? DateTime.now().toIso8601String(),
        'bus_number': busNumber,
        'eta_minutes': eta,
        'schedule_id': scheduleId,
      };
    } catch (e) {
      print('Error getting bus location: $e');
      
      // Return mock data with a more reasonable ETA
      return {
        'current_location': 'Jurong West',
        'destination': 'Tampines',
        'eta': '18:15',
        'current_time': '17:45',
        'progress': 0.65, // 65% of the journey completed
        'stops': [
          {'name': 'NTU', 'time': '17:00', 'passed': true},
          {'name': 'Jurong West', 'time': '17:15', 'passed': true},
          {'name': 'Bukit Batok', 'time': '17:30', 'passed': true},
          {'name': 'Bukit Timah', 'time': '17:45', 'passed': false},
          {'name': 'Toa Payoh', 'time': '18:00', 'passed': false},
          {'name': 'Tampines', 'time': '18:15', 'passed': false},
        ],
        'latitude': 1.3521,
        'longitude': 103.8198,
        'last_update': DateTime.now().toIso8601String(),
        'bus_number': 'SMB123S',
        'eta_minutes': CommuterService.getSharedETA(0),
        'schedule_id': 0,
      };
    }
  }
  
  // Helper method to generate stops based on pickup and destination
  List<Map<String, dynamic>> _generateStops(String pickup, String destination, String startTime, double progress, int etaMinutes) {
    List<Map<String, dynamic>> stops = [];
  
    // Add pickup as first stop
    stops.add({
      'name': pickup,
      'time': startTime.substring(0, 5),
      'passed': progress > 0.1,
    });
  
    // Add destination as last stop (no intermediate stops)
    stops.add({
      'name': destination,
      'time': _addMinutesToTime(startTime, etaMinutes),
      'passed': progress >= 1.0,
    });
  
    return stops;
  }
  
  // Helper method to determine current location based on progress
  String _determineCurrentLocation(List<Map<String, dynamic>> stops, double progress) {
    if (progress < 0.1) {
      return stops[0]['name']; // At origin
    } else if (progress >= 0.9) {
      return stops[1]['name']; // At destination
    } else {
      // In transit between origin and destination
      return "En route to ${stops[1]['name']}";
    }
  }
  
  // Helper method to get bus number based on route
  String _getBusNumber(String pickup, String destination) {
    if (pickup == 'NTU' && destination == 'Tampines') {
      return 'SMB123S';
    } else if (pickup == 'Punggol' && destination == 'Woodlands') {
      return 'SMB456T';
    } else if (pickup == 'Changi' && destination == 'Jurong East') {
      return 'SMB789U';
    } else {
      return 'SMB' + (pickup.hashCode % 1000).toString() + 'X';
    }
  }
  
  // Helper method to add minutes to a time string
  String _addMinutesToTime(String timeStr, int minutes) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final time = DateTime(2025, 1, 1, hour, minute);
    final newTime = time.add(Duration(minutes: minutes));
    
    return '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}';
  }
}

