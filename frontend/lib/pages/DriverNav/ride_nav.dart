import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
    initialZoom: 13.0

  );

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
            )
          ]),

    );
  }
}
