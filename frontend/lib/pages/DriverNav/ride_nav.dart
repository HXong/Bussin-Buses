import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class RideNav extends StatefulWidget {
  const RideNav({super.key});

  @override
  State<RideNav> createState() => _RideNavState();
}

class _RideNavState extends State<RideNav> {
  final mapController = MapController();
  final options = MapOptions(
    initialCenter: LatLng(1.3521, 103.8198),
    initialZoom: 16.0

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

  var coordinates = [LatLng(1.3721, 103.9474), LatLng(1.3555, 103.9520), LatLng(1.3496, 103.9568)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
          mapController: mapController,
          options: options,
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
              maxZoom: 19,
            ),
            CurrentLocationLayer(
              alignPositionOnUpdate: AlignOnUpdate.always,
            ),
            PolylineLayer(polylines: [
              Polyline(points: coordinates, color: Colors.blue, strokeWidth: 6.0)
            ]),
            ElevatedButton(onPressed: () {startJourney();}, child: Text("Start Journey"))

          ]),


    );
  }
}
