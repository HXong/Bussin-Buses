import 'package:bussin_buses/models/Passengers.dart';
import 'package:bussin_buses/services/driver_service.dart';
import 'package:bussin_buses/services/supabase_client_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/Trips.dart';

class TripViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseClientService.client;
  List<Trip> upcomingConfirmedTrips = [];
  List<Trip> upcomingAllTrips = [];
  List<Trip> pastTrips = [];
  List<Passenger> passengers = [];
  bool isLoading = false;
  bool isSubmitJourneyLoading = false;
  bool hasFetchedAllTrips = false;
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
    hasFetchedAllTrips = false;
    notifyListeners();

    upcomingAllTrips = await _driverService.fetchTrips("", targetDate, false, false);

    isLoading = false;
    hasFetchedAllTrips = true;
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
    trip.status = 'DELETED';
    upcomingConfirmedTrips.removeWhere((t) => t.scheduleId == trip.scheduleId);
    int index = upcomingAllTrips.indexWhere((t) => t.scheduleId == trip.scheduleId);
    if (index != -1) {
      upcomingAllTrips[index].status = 'DELETED';
    }


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
    final driverName = await _driverService.fetchDriverName(driverId);
    final pickupId = await _driverService.getLocationIdByName(selectedPickup!);
    final destinationId = await _driverService.getLocationIdByName(selectedDestination!);
    DateTime selectedDateTime = DateTime.parse("$date $time");
    DateTime endDateTime = selectedDateTime.add(const Duration(minutes: 75));
    final existingTrips = await _driverService.fetchTrips(driverId, DateTime.parse(date), false, true); //Fetch future trips
    final formattedDate = await _driverService.formatDate(date);
    final theDaySchedules = existingTrips
        .where((trip) => trip.date == formattedDate)
        .map((trip) => trip.startTime)
        .toList();

    if (selectedDateTime.isBefore(timeNow)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("The schedule must be in the future.")));
      isSubmitJourneyLoading = false;
      notifyListeners();
      return;
    }

    for (var scheduleTime in theDaySchedules) {
      final existingScheduleDateTime = DateTime.parse("$date $scheduleTime");

      if ((selectedDateTime.difference(existingScheduleDateTime).inHours).abs() < 5) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("You must have at least 5 hours between trips.")));
        isSubmitJourneyLoading = false;
        notifyListeners();
        return;
      }
    }
    print("Before adding new trip: ${upcomingConfirmedTrips.length}");

    final scheduleId = await _driverService.addJourney(
      pickupId: pickupId,
      destinationId: destinationId,
      date: date,
      time: time,
      driverId: driverId,
    );

    int duration = await _driverService.getETA(scheduleId);
    endDateTime = selectedDateTime.add(Duration(minutes: duration));
    final updatedTrip = Trip(
      scheduleId: scheduleId,
      driverName: driverName,
      date: formattedDate,
      startTime: time.substring(0, 5),
      endTime: DateFormat('HH:mm').format(endDateTime),
      duration: "$duration mins",
      pickup: selectedPickup!,
      destination: selectedDestination!,
      status: 'CONFIRMED',
      isJourneyStarted: false,
    );
    upcomingConfirmedTrips.add(updatedTrip);
    print("BEFORe: ${upcomingAllTrips.length}");
    upcomingAllTrips.add(updatedTrip);
    print("AFTER: ${upcomingAllTrips.length}");

    // sorting the list
    upcomingConfirmedTrips = await sortList(upcomingConfirmedTrips);
    upcomingAllTrips = await sortList(upcomingAllTrips);

    isSubmitJourneyLoading = false;
    notifyListeners();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Journey added successfully!")));
    dateController.clear();
    pickedTime = null;
    selectedPickup = null;
    selectedDestination = null;
  }

  Future<List<Trip>> sortList(List<Trip> trips) async {
    List<MapEntry<Trip, DateTime>> tripDateTimePairs = [];
    for (var trip in trips) {
      DateTime tripDateTime = await _driverService.fetchDateTime(trip.scheduleId);
      tripDateTimePairs.add(MapEntry(trip, tripDateTime));
    }
    tripDateTimePairs.sort((a, b) => a.value.compareTo(b.value));
    return tripDateTimePairs.map((entry) => entry.key).toList();
  }


  Future<void> fetchPassengerDetails(String scheduleId) async {
    isLoading = true;
    notifyListeners();
    passengers = await _driverService.fetchPassengerDetails(scheduleId);
    isLoading = false;
    notifyListeners();
  }

  void reset() {
    upcomingConfirmedTrips = [];
    upcomingAllTrips = [];
    pastTrips = [];
    passengers = [];
    isLoading = false;
    isSubmitJourneyLoading = false;
    currentTripDetails = null;
    notifyListeners();
  }


}