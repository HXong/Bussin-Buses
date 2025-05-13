import 'dart:async';
import 'package:bussin_buses/services/route_service.dart';
import 'package:bussin_buses/services/supabase_client_service.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/RouteResponse.dart';
import '../services/driver_service.dart';

/// JourneyTrackingViewModel handles methods related to the driver's location and routing.
/// It also handles the subscription for the rerouting so that when there is a notification update in Supabase,
/// the driver will receive the notifications and ping the backend for another route from the driver's current location to the destination
class JourneyTrackingViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseClientService.client;
  final DriverService _driverService;
  final RouteService _routeService;

  List<String> locations = [];
  List<LatLng> polylineCoordinates = [];

  String estimatedArrivalTime = "";
  String message = "";

  Timer? _locationUpdateTimer;
  bool isStartJourney = false;

  /// Subscription for notifications table in Supabase
  StreamSubscription<Map<String,dynamic>>? _subscription;

  JourneyTrackingViewModel(this._driverService, this._routeService);

  /// gets all the locations from Supabase to display
  Future<void> loadLocations() async {
    locations = await _driverService.fetchLocations();
    notifyListeners();
  }

  /// Gets the current location from the device GPS and updates the driver's location on Supabase in the driver_location table
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

  /// start pinging the GPS every minute
  void _startLocationUpdates() {
    _updateLocation();
    _locationUpdateTimer = Timer.periodic(Duration(minutes: 1), (_) async {
      await _updateLocation();
    });
  }

  /// stop pinging GPS
  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
  }

  /// get the route + polyline + ETA and change journey_started state to true in Supabase.
  /// displays the data onto the ride_nav.dart screen as well
  Future<void> startJourney(String driverId, String scheduleId) async {
    _startLocationUpdates();
    polylineCoordinates.clear();
    RouteResponse routeResponse = await _routeService.startJourney(driverId, scheduleId);
    polylineCoordinates = routeResponse.decodedRoute;
    estimatedArrivalTime = getFormattedTimeAfter(routeResponse.duration);
    isStartJourney = true;

    _driverService.subscribeToNotifications();
    _subscription ??= _driverService.updates.listen((data) => _handleNotification(data), onError: (e) {
        print("Stream error: $e");
      });
  }

  /// stops location updates, updates journey_started to false in Supabase through backend stop-journey route
  Future<void> stopJourney(String driverId, String scheduleId, VoidCallback? onSuccess) async {

    _stopLocationUpdates();
    int responseCode = await _routeService.stopJourney(driverId, scheduleId);
    if (responseCode == 0) {
      // stopped successfully
      isStartJourney = false;
      polylineCoordinates.clear();
      onSuccess?.call();
      _driverService.unsubscribeToNotifications();
      await _subscription?.cancel();
      _subscription = null;
      notifyListeners();
    }
    else {
      // something went wrong
    }
  }

  /// notification handler when there is a new notification in the Supabase notifications table meant for the driver
  void _handleNotification(data) async {
    final rerouteData = await _routeService.getReroute(_supabase.auth.currentUser!.id);
    polylineCoordinates.clear();
    polylineCoordinates.addAll(rerouteData.decodedRoute);
    estimatedArrivalTime = getFormattedTimeAfter(rerouteData.duration);
    message = data["message"];
    notifyListeners();
  }

  /// reroute when user clicks 'Navigate' during 'in progress' status
  void reroute() async {
    final rerouteData = await _routeService.getReroute(_supabase.auth.currentUser!.id);
    polylineCoordinates.clear();
    polylineCoordinates.addAll(rerouteData.decodedRoute);
    estimatedArrivalTime = getFormattedTimeAfter(rerouteData.duration);
    notifyListeners();
  }

  String getFormattedTimeAfter(int duration) {
    final currentTime = DateTime.now();
    final eta =  currentTime.add(Duration(seconds: duration));
    return DateFormat('hh:mm a').format(eta);
  }

  void clearMsg() {
    message = "";
    notifyListeners();
  }

  void reset() {
    locations = [];
    polylineCoordinates = [];

    estimatedArrivalTime = "";
    message = "";

    _locationUpdateTimer;
    isStartJourney = false;
    _subscription = null;
    notifyListeners();
  }

}