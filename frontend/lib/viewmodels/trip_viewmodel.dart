import 'package:bussin_buses/models/Passengers.dart';
import 'package:bussin_buses/services/driver_service.dart';
import 'package:bussin_buses/services/supabase_client_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/Trips.dart';

class TripViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseClientService.client;
  List<Trip> upcomingConfirmedTrips = [];
  List<Trip> upcomingAllTrips = [];
  List<Trip> pastTrips = [];
  List<Passenger> passengers = [];
  bool isLoading = false;
  bool isSubmitJourneyLoading = false;
  Trip? currentTripDetails;
  String? pickedTime;
  String? selectedPickup;
  String? selectedDestination;
  final DriverService _driverService;
  final timeNow = DateTime.now().toUtc().add(const Duration(hours: 8));
  final TextEditingController dateController = TextEditingController();


  TripViewModel(this._driverService) {
    fetchUpcomingConfirmedTrips(timeNow);
    fetchAllUpcomingTrips(timeNow);
    fetchPastTrips(timeNow);
  }
  Future<void> fetchUpcomingConfirmedTrips(DateTime targetDate) async {
    isLoading = true;
    notifyListeners();
    final driverId = _supabase.auth.currentUser?.id;

    if (driverId == null) {
      debugPrint('No user is logged in.');
      return;
    }

    upcomingConfirmedTrips = await _driverService.fetchTrips(driverId, targetDate, false, true);
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllUpcomingTrips(DateTime targetDate) async {
    isLoading = true;
    notifyListeners();

    upcomingAllTrips = await _driverService.fetchTrips("", targetDate, false, false);
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

  Future<void> deleteTrip(Trip trip) async {
    await _driverService.deleteTrip(trip);

    // Remove the trip using the Trip object's scheduleId
    upcomingConfirmedTrips.removeWhere((t) => t.scheduleId == trip.scheduleId);

    await fetchAllUpcomingTrips(timeNow);
    notifyListeners();
  }

  void updateSelectedPickup(String? newPickup) {
    selectedPickup = newPickup;
    notifyListeners();
  }

  void updateSelectedDestination(String? newDestination) {
    selectedDestination = newDestination;
    notifyListeners();
  }

  void updateSelectedTime(String? newTime){
    pickedTime = newTime;
    notifyListeners();
  }

  Future<void> submitJourney(BuildContext context) async {
    final date = dateController.text;
    final time = pickedTime;

    if (selectedPickup == null || selectedDestination == null || date.isEmpty || time == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please fill in all fields.")));
      return;
    }

    if (selectedPickup == selectedDestination) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Pickup and destination points have to be different.")));
      return;
    }
    isSubmitJourneyLoading = true;
    notifyListeners();

    final driverId = _supabase.auth.currentUser!.id;
    final pickupId = await _driverService.getLocationIdByName(selectedPickup!);
    final destinationId = await _driverService.getLocationIdByName(selectedDestination!);
    final selectedDateTime = DateTime.parse("$date $time");
    final existingTrips = await _driverService.fetchTrips(driverId, DateTime.parse(date), false, true); //Fetch future trips

    final theDaySchedules = existingTrips
        .where((trip) => trip.date == date)
        .map((trip) => trip.startTime)
        .toList();

    if (selectedDateTime.isBefore(timeNow)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("The schedule must be in the future.")));
      return;
    }

    for (var scheduleTime in theDaySchedules) {
      final existingTime = DateTime.parse("$date $scheduleTime");
      if ((selectedDateTime.difference(existingTime).inHours).abs() < 5) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("You must have at least 5 hours between trips.")));
        return;
      }
    }

    await _driverService.addJourney(
      pickupId: pickupId,
      destinationId: destinationId,
      date: date,
      time: time,
      driverId: driverId,
    );

    isSubmitJourneyLoading = false;
    notifyListeners();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Journey added successfully!")));

    dateController.clear();
    pickedTime = null;
    selectedPickup = null;
    selectedDestination = null;
    await fetchUpcomingConfirmedTrips(timeNow);
    await fetchAllUpcomingTrips(timeNow);
  }

  Future<void> fetchPassengerDetails(String scheduleId) async {
    isLoading = true;
    notifyListeners();
    passengers = await _driverService.fetchPassengerDetails(scheduleId);
    isLoading = false;
    notifyListeners();
  }


}