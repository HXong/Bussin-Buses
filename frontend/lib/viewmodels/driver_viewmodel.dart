import 'package:bussin_buses/models/RouteResponse.dart';
import 'package:bussin_buses/services/route_service.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/driver_service.dart';
import '../services/supabase_client_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverViewModel extends ChangeNotifier {
  final DriverService _driverService;
  final RouteService _routeService;
  final SupabaseClient _supabase = SupabaseClientService.client;

  List<Map<String, dynamic>> passengers = [];
  List<Map<String, dynamic>> upcomingConfirmedTrips = [];
  List<Map<String, dynamic>> upcomingAllTrips = [];
  List<Map<String, dynamic>> pastTrips = [];
  List<LatLng> polylineCoordinates = [];
  Map<String, dynamic> driverProfile = {};
  bool isLoading = false;
  int selectedIndex = 0;
  Map<String, dynamic> currentTripDetails = {};
  bool isStartJourney = false;

  final TextEditingController dateController = TextEditingController();
  final TextEditingController feedbackController = TextEditingController();

  List<String> locations = [];
  String? pickedTime;
  String? selectedPickup;
  String? selectedDestination;

  DriverViewModel(this._driverService, this._routeService) {
    fetchUpcomingConfirmedTrips(DateTime.now());
    fetchAllUpcomingTrips(DateTime.now());
    fetchPastTrips(DateTime.now());
    fetchPersonalInformation();
  }

  Future<void> fetchUpcomingConfirmedTrips(DateTime targetDate) async {
    isLoading = true;
    notifyListeners();
    final driverId = _supabase.auth.currentUser?.id;

    if (driverId == null) {
      debugPrint('No user is logged in.');
      return;
    }

    List<Map<String, dynamic>> tripsWithLocations = await _driverService.fetchTrips(driverId, targetDate, false, true);
    upcomingConfirmedTrips = tripsWithLocations;
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllUpcomingTrips(DateTime targetDate) async {
    isLoading = true;
    notifyListeners();

    List<Map<String, dynamic>> tripsWithLocations = await _driverService.fetchTrips("", targetDate, false, false);
    upcomingAllTrips = tripsWithLocations;
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPastTrips(DateTime targetDate) async {
    isLoading = true;
    notifyListeners();
    final driverId = _supabase.auth.currentUser!.id;
    List<Map<String, dynamic>> tripsWithLocations = await _driverService.fetchTrips(driverId, targetDate, true, false);
    pastTrips = tripsWithLocations;
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPassengerDetails(String scheduleId) async {
    isLoading = true;
    notifyListeners();
    passengers = await _driverService.fetchPassengerDetails(scheduleId);
    isLoading = false;
    notifyListeners();
  }

  Future<void> deleteTrip(Map<String, dynamic> trip) async {
    await _driverService.deleteTrip(trip);
    upcomingConfirmedTrips.removeWhere((t) => t['schedule_id'] == trip['schedule_id']);
    await fetchAllUpcomingTrips(DateTime.now());
    notifyListeners();
  }

  Future<void> loadLocations() async {
    locations = await _driverService.fetchLocations();
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

  Future<void> submitJourney(BuildContext context) async {
    final date = dateController.text;
    final time = pickedTime;

    if (selectedPickup == null || selectedDestination == null || date.isEmpty || time == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all fields.")));
      return;
    }

    if (selectedPickup == selectedDestination) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pickup and destination points have to be different.")));
      return;
    }

    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid date format. Use yyyy-MM-dd.")));
      return;
    }

    final driverId = _supabase.auth.currentUser!.id;
    final pickupId = await _driverService.getLocationIdByName(selectedPickup!);
    final destinationId = await _driverService.getLocationIdByName(selectedDestination!);
    final selectedTime = DateTime.parse("$date $time");
    final existingTrips = await _driverService.fetchTrips(driverId, DateTime.parse(date), false, true); //Fetch future trips
    final theDaySchedules = existingTrips
        .where((trip) => trip['date'] == date) //include only those on the selected date
        .map((trip) => trip['start_time'].toString())
        .toList();

    if (selectedTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("The schedule must be in the future.")));
      return;
    }

    for (var scheduleTime in theDaySchedules) {
      final existingTime = DateTime.parse("$date $scheduleTime");
      if ((selectedTime.difference(existingTime).inHours).abs() < 5) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You must have at least 5 hours between trips.")));
        return;
      }
    }

    await _driverService.addJourney(pickupId: pickupId, destinationId: destinationId, date: date, time: time, driverId: driverId,);

    dateController.clear();
    pickedTime = null;
    selectedPickup = null;
    selectedDestination = null;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Journey added successfully!")));

    await fetchUpcomingConfirmedTrips(DateTime.now());
    await fetchAllUpcomingTrips(DateTime.now());

    notifyListeners();
  }

  Future<void> fetchPersonalInformation() async {
    final driverId = _supabase.auth.currentUser?.id;
    if (driverId == null) {
      return;
    }

    final profile = await _driverService.fetchDriverProfile(driverId);
    final busPlate = await _driverService.fetchBusPlate(driverId);
    driverProfile = {...profile, 'bus_plate': busPlate};

    notifyListeners();
  }

  Future<void> submitFeedback(BuildContext context) async{
      final feedback = feedbackController.text;

      if (feedback.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter feedback.")));
        return;
      }
      final driverId = _supabase.auth.currentUser!.id;
      await _driverService.storeFeedback(feedback, driverId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Feedback submitted successfully!")));
      feedbackController.clear();
  }

  void setPageIndex(int newIndex) {
    selectedIndex = newIndex;
    notifyListeners();
  }

  Future<void> startJourney(String driverId, String scheduleId) async {
    polylineCoordinates.clear();
    RouteResponse routeResponse = await _routeService.startJourney(driverId, scheduleId);
    polylineCoordinates = routeResponse.decodedRoute;
    isStartJourney = true;
    notifyListeners();
  }

  Future<void> stopJourney(String driverId, String scheduleId) async {
    int responseCode = await _routeService.stopJourney(driverId, scheduleId);
    if (responseCode == 0) {
      // stopped successfully
      isStartJourney = false;
      polylineCoordinates.clear();
      // TODO: do something to end trip?
      fetchUpcomingConfirmedTrips(DateTime.now());
      currentTripDetails.clear();
    }
    else {
      // something went wrong
    }
  }
}