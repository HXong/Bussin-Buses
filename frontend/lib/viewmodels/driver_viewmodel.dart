import 'package:flutter/material.dart';
import '../services/driver_service.dart';
import '../services/supabase_client_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverViewModel extends ChangeNotifier {
  final DriverService _driverService;
  final SupabaseClient _supabase = SupabaseClientService.client;

  List<Map<String, dynamic>> passengers = [];
  List<Map<String, dynamic>> upcomingTrips = [];
  List<Map<String, dynamic>> pastTrips = [];
  bool isLoading = false;

  DriverViewModel(this._driverService) {
    fetchUpcomingTrips(DateTime.now());

  }

  Future<void> fetchUpcomingTrips(DateTime targetDate) async {
    isLoading = true;
    notifyListeners();
    final driverId = _supabase.auth.currentUser?.id;

    if (driverId == null) {
      debugPrint('No user is logged in.');
      return;
    }

    List<Map<String, dynamic>> tripsWithLocations = await _driverService.fetchTrips(driverId, targetDate, false, true);
    upcomingTrips = tripsWithLocations;
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPastTrips(DateTime targetDate) async {
    isLoading = true;
    notifyListeners();
    final driverId = _supabase.auth.currentUser!.id;
    pastTrips = await _driverService.fetchTrips(driverId, targetDate, true, false);
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPassengerDetails(String scheduleId) async {
    isLoading = true;
    notifyListeners(); // Notify UI to show loading indicator

    passengers = await _driverService.fetchPassengerDetails(scheduleId);

    isLoading = false;
    notifyListeners(); // Notify UI to refresh passenger list
  }

  Future<void> deleteTrip(Map<String, dynamic> trip) async {
    await _driverService.deleteTrip(trip);upcomingTrips.removeWhere((t) => t['schedule_id'] == trip['schedule_id']);
    upcomingTrips.removeWhere((t) => t['schedule_id'] == trip['schedule_id']);
    notifyListeners();
  }


}