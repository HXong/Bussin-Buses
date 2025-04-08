
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
  StreamSubscription<Map<String,dynamic>>? _subscription;


  JourneyTrackingViewModel(this._driverService, this._routeService);

  Future<void> loadLocations() async {
    locations = await _driverService.fetchLocations();
    notifyListeners();
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

  void _startLocationUpdates() {
    _updateLocation();
    _locationUpdateTimer = Timer.periodic(Duration(minutes: 1), (_) async {
      await _updateLocation();
    });
  }

  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
  }

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
    notifyListeners();
  }

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

  void _handleNotification(data) async {
    final rerouteData = await _routeService.getReroute(_supabase.auth.currentUser!.id);
    polylineCoordinates.clear();
    polylineCoordinates.addAll(rerouteData.decodedRoute);
    estimatedArrivalTime = getFormattedTimeAfter(rerouteData.duration);
    message = data["message"];
    notifyListeners();
  }

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