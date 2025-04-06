// lib/pages/CommuterNav/live_location_nav.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../viewmodels/live_location_viewmodel.dart';
import '../../services/live_location_service.dart';

class LiveLocationNav extends StatefulWidget {
  final int? bookingId;
  
  const LiveLocationNav({this.bookingId, Key? key}) : super(key: key);

  @override
  State<LiveLocationNav> createState() => _LiveLocationNavState();
}

class _LiveLocationNavState extends State<LiveLocationNav> {
  late LiveLocationViewModel _viewModel;
  
  @override
  void initState() {
    super.initState();
    _viewModel = LiveLocationViewModel(LiveLocationService());
    
    if (widget.bookingId != null) {
      _viewModel.init(widget.bookingId!);
    }
  }
  
  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<LiveLocationViewModel>(
        builder: (context, viewModel, _) {
          final busLocation = viewModel.busLocation;
          
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Live Location',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                // Add refresh button
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.black),
                  onPressed: () {
                    viewModel.refreshLocation();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Refreshing location and ETA...'))
                    );
                  },
                ),
              ],
            ),
            body: viewModel.isLoading && !viewModel.hasData
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bus route info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${busLocation['stops']?.first['name'] ?? 'Origin'} - ${busLocation['destination'] ?? 'Destination'}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "20 Jan, 2025 | Bus ${busLocation['bus_number'] ?? 'SMB1235'}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Current location and ETA
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Current Location",
                                      style: TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                    Text(
                                      busLocation['current_location'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      "ETA",
                                      style: TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          busLocation['eta'] ?? '--:--',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (busLocation.containsKey('eta_minutes'))
                                          Text(
                                            " (${busLocation['eta_minutes']}m)",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: busLocation['progress'] ?? 0.0,
                                backgroundColor: Colors.grey[400],
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                                minHeight: 10,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Origin and destination
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  busLocation['stops']?.first['name'] ?? 'Origin',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  busLocation['destination'] ?? 'Destination',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Map view
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildMap(viewModel),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Journey details
                      const Text(
                        "Journey Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Only show start and destination
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Departure
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (busLocation['progress'] ?? 0.0) > 0.1 ? Colors.green : Colors.grey[400],
                                  ),
                                  child: (busLocation['progress'] ?? 0.0) > 0.1
                                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Departure",
                                            style: TextStyle(fontSize: 12, color: Colors.black54),
                                          ),
                                          Text(
                                            busLocation['stops']?.first['name'] ?? 'Origin',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        busLocation['stops']?.first['time'] ?? '--:--',
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            // Vertical line
                            Container(
                              margin: const EdgeInsets.only(left: 7.5, top: 8, bottom: 8),
                              width: 1,
                              height: 30,
                              color: Colors.grey[400],
                            ),
                            
                            // Arrival
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (busLocation['progress'] ?? 0.0) >= 1.0 ? Colors.green : Colors.grey[400],
                                  ),
                                  child: (busLocation['progress'] ?? 0.0) >= 1.0
                                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Arrival",
                                            style: TextStyle(fontSize: 12, color: Colors.black54),
                                          ),
                                          Text(
                                            busLocation['destination'] ?? 'Destination',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        busLocation['stops']?.last['time'] ?? '--:--',
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Journey status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Bus is ${busLocation['current_location']}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  Text(
                                    "${((busLocation['progress'] ?? 0.0) * 100).round()}% of journey completed",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          );
        },
      ),
    );
  }
  
  Widget _buildMap(LiveLocationViewModel viewModel) {
    final currentLocation = viewModel.getCurrentLocation();
    
    if (currentLocation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.map, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text("Map data unavailable", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return FlutterMap(
      options: MapOptions(
        initialCenter: currentLocation,
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: currentLocation,
              width: 80,
              height: 80,
              child: const Icon(
                Icons.directions_bus,
                color: Colors.blue,
                size: 30,
              ),
            ),
          ],
        ),
      ],
    );
  }
}