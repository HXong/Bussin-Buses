// lib/viewmodels/live_location_viewmodel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/live_location_service.dart';

class LiveLocationViewModel extends ChangeNotifier {
  final LiveLocationService _service;
  bool isLoading = true;
  bool hasData = false;
  Map<String, dynamic> busLocation = {};
  Timer? _refreshTimer;

  LiveLocationViewModel(this._service);

  Future<void> init(int bookingId) async {
    isLoading = true;
    notifyListeners();
    
    try {
      busLocation = await _service.getBusLiveLocation(bookingId);
      hasData = true;
      
      // Set up a timer to refresh the location every 30 seconds
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        refreshLocation(bookingId);
      });
    } catch (e) {
      print('Error initializing live location: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> refreshLocation(int bookingId) async {
    try {
      final updatedLocation = await _service.getBusLiveLocation(bookingId);
      busLocation = updatedLocation;
      notifyListeners();
    } catch (e) {
      print('Error refreshing location: $e');
    }
  }
  
  LatLng? getCurrentLocation() {
    if (busLocation.containsKey('latitude') && busLocation.containsKey('longitude')) {
      return LatLng(
        busLocation['latitude'] as double,
        busLocation['longitude'] as double,
      );
    }
    return null;
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

