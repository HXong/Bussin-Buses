import 'package:bussin_buses/viewmodels/auth_viewmodel.dart';
import 'package:bussin_buses/viewmodels/journey_tracking_viewmodel.dart';
import 'package:bussin_buses/viewmodels/trip_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class RideNav extends StatefulWidget {
  const RideNav({super.key});

  @override
  State<RideNav> createState() => _RideNavState();
}

class _RideNavState extends State<RideNav> {
  final mapController = MapController();
  final options = MapOptions(
    initialCenter: LatLng(1.3521, 103.8198),
    initialZoom: 16.0,
  );
  LocationPermission? _permission;

  Future<void> _checkPermission() async {
    _permission = await Geolocator.checkPermission();

    // Request permission if initially denied
    if (_permission == LocationPermission.denied) {
      _permission = await Geolocator.requestPermission();
    }
  }

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final tripViewModel = Provider.of<TripViewModel>(context);
    final routeViewModel = Provider.of<JourneyTrackingViewModel>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (routeViewModel.message != "") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(routeViewModel.message)),
        );
        routeViewModel.clearMsg();
      }
    });

    return Scaffold(
      body:
        tripViewModel.currentTripDetails == null
              ? Center(child: Text("No journey started"))
              : FlutterMap(
                mapController: mapController,
                options: options,
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                    maxZoom: 19,
                  ),
                  CurrentLocationLayer(
                    alignPositionOnUpdate: AlignOnUpdate.always,
                  ),
                  routeViewModel.polylineCoordinates.isNotEmpty
                      ? PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routeViewModel.polylineCoordinates,
                            color: Colors.blue,
                            strokeWidth: 6.0,
                          ),
                        ],
                      )
                      : const SizedBox(),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      color: Colors.white.withValues(alpha: 0.8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              routeViewModel.estimatedArrivalTime != "" ? Text("Estimated Time of Arrival: ${routeViewModel.estimatedArrivalTime}") : Text(""),
                              Text(
                                "Pick Up: ${tripViewModel.currentTripDetails?.pickup}",
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                "Destination: ${tripViewModel.currentTripDetails?.destination}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (!routeViewModel.isStartJourney)
                            ElevatedButton(
                              onPressed: () {
                                String? scheduleId =
                                    tripViewModel
                                        .currentTripDetails?.scheduleId;
                                routeViewModel.startJourney(
                                  authViewModel.user!.id,
                                  scheduleId.toString(),
                                );
                              },
                              child: const Text("Start Journey"),
                            ),
                          if (routeViewModel.isStartJourney)
                            ElevatedButton(
                              onPressed: () {
                                String? scheduleId =
                                    tripViewModel
                                        .currentTripDetails?.scheduleId;
                                routeViewModel.stopJourney(
                                  authViewModel.user!.id,
                                  scheduleId.toString(),
                                    () {
                                      tripViewModel.fetchUpcomingConfirmedTrips(DateTime.now());
                                      tripViewModel.currentTripDetails = null;
                                    }
                                );
                              },
                              child: const Text("Stop Journey"),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Column(
                  //   children: [
                  //     Text("Pick Up: ${driverViewModel.currentTripDetails["pickup"]}"),
                  //     Text("Destination: ${driverViewModel.currentTripDetails["destination"]}"),
                  //     if (!driverViewModel.isStartJourney)
                  //     ElevatedButton(onPressed: () {
                  //       int scheduleId = driverViewModel.currentTripDetails["schedule_id"];
                  //       driverViewModel.startJourney(authViewModel.user!.id, scheduleId.toString());
                  //
                  //       }, child: Text("Start Journey")),
                  //     if (driverViewModel.isStartJourney)
                  //     ElevatedButton(onPressed: () {
                  //       int scheduleId = driverViewModel.currentTripDetails["schedule_id"];
                  //       driverViewModel.stopJourney(authViewModel.user!.id, scheduleId.toString());
                  //     }, child: Text("Stop Journey")),
                  //
                  //   ],
                  // )
                ],
              ),
    );
  }
}
