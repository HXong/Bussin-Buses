import 'dart:async';
import 'package:bussin_buses/models/Passengers.dart';
import 'package:bussin_buses/models/Trips.dart';
import 'package:bussin_buses/models/RouteResponse.dart';
import 'package:bussin_buses/models/DriverProfile.dart';
import 'package:bussin_buses/services/route_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../services/driver_service.dart';
import '../services/supabase_client_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverViewModel extends ChangeNotifier {
  final DriverService _driverService;
  final RouteService _routeService;
  final SupabaseClient _supabase = SupabaseClientService.client;

  List<Passenger> passengers = [];
  List<Trip> upcomingConfirmedTrips = [];
  List<Trip> upcomingAllTrips = [];
  List<Trip> pastTrips = [];
  List<LatLng> polylineCoordinates = [];
  String estimatedArrivalTime = "";
  DriverProfile? driverProfile;
  Trip? currentTripDetails;
  bool isLoading = false;
  int selectedIndex = 0;
  bool isStartJourney = false;
  String message = "";

  final TextEditingController dateController = TextEditingController();
  final TextEditingController feedbackController = TextEditingController();

  List<String> locations = [];
  final timeNow = DateTime.now().toUtc().add(const Duration(hours: 8));
  String? pickedTime;
  String? selectedPickup;
  String? selectedDestination;

  Timer? _locationUpdateTimer;
  StreamSubscription<Map<String,dynamic>>? _subscription;

  DriverViewModel(this._driverService, this._routeService) {
    fetchUpcomingConfirmedTrips(timeNow);
    fetchAllUpcomingTrips(timeNow);
    fetchPastTrips(timeNow);
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

  Future<void> fetchPassengerDetails(String scheduleId) async {
    isLoading = true;
    notifyListeners();
    passengers = await _driverService.fetchPassengerDetails(scheduleId);
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

  void updateSelectedTime (String? newTime){
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

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Journey added successfully!")));

    dateController.clear();
    pickedTime = null;
    selectedPickup = null;
    selectedDestination = null;
    await fetchUpcomingConfirmedTrips(timeNow);
    await fetchAllUpcomingTrips(timeNow);
    notifyListeners();
  }

  Future<void> fetchPersonalInformation() async {
    final driverId = _supabase.auth.currentUser?.id;

    if (driverId == null) {
      print('Driver ID is null');
      return;
    }
    try {
      final profileData = await _driverService.fetchDriverProfile(driverId);
      final busPlate = await _driverService.fetchBusPlate(driverId);
      driverProfile = DriverProfile.fromMap(profileData, busPlate);
      notifyListeners();

    } catch (e) {
      print('Error fetching personal information: $e');
    }
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
    _startLocationUpdates();
    polylineCoordinates.clear();
    RouteResponse routeResponse = await _routeService.startJourney(driverId, scheduleId);
    polylineCoordinates = routeResponse.decodedRoute;
    estimatedArrivalTime = getFormattedTimeAfter(routeResponse.duration);
    isStartJourney = true;
    _driverService.subscribeToNotifications();
    _subscription = _driverService.updates.listen((data) => _handleNotification(data), onError: (e) {
      print("Stream error: $e");
    });
    notifyListeners();
  }

  Future<void> stopJourney(String driverId, String scheduleId) async {

    _stopLocationUpdates();
    int responseCode = await _routeService.stopJourney(driverId, scheduleId);
    if (responseCode == 0) {
      // stopped successfully
      isStartJourney = false;
      polylineCoordinates.clear();
      // TODO: do something to end trip?
      fetchUpcomingConfirmedTrips(timeNow);
      currentTripDetails = null;
      _driverService.unsubscribeToNotifications();
      _subscription = null;
      notifyListeners();
    }
    else {
      // something went wrong
    }
  }

  String getFormattedTimeAfter(int duration) {
    final currentTime = DateTime.now();
    final eta =  currentTime.add(Duration(seconds: duration));
    return DateFormat('hh:mm a').format(eta);
  }

  void _startLocationUpdates() {
    _updateLocation();
    _locationUpdateTimer = Timer.periodic(Duration(minutes: 1), (_) async {
      await _updateLocation();
    });
  }

  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
  }

  Future<void> _updateLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();

      await _driverService.updateDriverLocation(
        _supabase.auth.currentUser!.id,
        position.latitude,
        position.longitude,
      );

      print("Location updated");
    } catch (e) {
      print("Failed to update location: $e");
    }
  }

  void _handleNotification(data) async {
    final rerouteData = await _routeService.getReroute(_supabase.auth.currentUser!.id);
    polylineCoordinates.clear();
    polylineCoordinates.addAll(rerouteData.decodedRoute);
    estimatedArrivalTime = getFormattedTimeAfter(rerouteData.duration);
    message = data["message"];
    notifyListeners();
  }

  void clearMsg() {
    message = "";
    notifyListeners();
  }

  @override
  void dispose() {
    _driverService.dispose();
    super.dispose();
  }
}