// lib/viewmodels/live_location_viewmodel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/live_location_service.dart';
import '../services/commuter_service.dart';
import 'package:intl/intl.dart';

class LiveLocationViewModel extends ChangeNotifier {
  final LiveLocationService _service;
  final CommuterService _commuterService = CommuterService();
  bool isLoading = true;
  bool hasData = false;
  Map<String, dynamic> busLocation = {};
  Timer? _refreshTimer;
  int _bookingId = 0;
  int _scheduleId = 0;
  DateTime _lastEtaUpdate = DateTime.now();
  final Duration _etaUpdateInterval = Duration(minutes: 2); // Update ETA every 2 minutes

  LiveLocationViewModel(this._service);

  Future<void> init(int bookingId) async {
    isLoading = true;
    _bookingId = bookingId;
    notifyListeners();
    
    try {
      await _fetchLocationData();
      hasData = true;
      
      // Set up a timer to refresh the location every 30 seconds
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        refreshLocation();
      });
    } catch (e) {
      print('Error initializing live location: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _fetchLocationData() async {
    busLocation = await _service.getBusLiveLocation(_bookingId);
    
    // Extract schedule ID if needed for ETA updates
    if (_scheduleId == 0 && busLocation.containsKey('schedule_id')) {
      _scheduleId = busLocation['schedule_id'];
    }
    
    // Check the shared cache for updates
    if (_scheduleId > 0 && CommuterService.isSharedETAValid(_scheduleId)) {
      final sharedEta = CommuterService.getSharedETA(_scheduleId);
      if (busLocation['eta_minutes'] != sharedEta) {
        busLocation['eta_minutes'] = sharedEta;
      }
    }
    
    // Update times based on current time
    _updateTimesWithCurrentTime();
    
    notifyListeners();
  }
  
  // New method to update all times based on current time
  void _updateTimesWithCurrentTime() {
    if (busLocation.containsKey('eta_minutes')) {
      final etaMinutes = busLocation['eta_minutes'] as int;
      final now = DateTime.now();
      final currentTime = DateFormat('HH:mm').format(now);
      final arrivalTime = now.add(Duration(minutes: etaMinutes));
      final formattedArrivalTime = DateFormat('HH:mm').format(arrivalTime);
      
      // Update current time
      busLocation['current_time'] = currentTime;
      
      // Update the ETA time
      busLocation['eta'] = formattedArrivalTime;
      
      // Update the stops if they exist
      if (busLocation.containsKey('stops') && 
          busLocation['stops'] is List && 
          busLocation['stops'].length >= 2) {
        
        // Update departure time (first stop) to current time
        busLocation['stops'][0]['time'] = currentTime;
        
        // Update arrival time (last stop) to current time + ETA
        busLocation['stops'][busLocation['stops'].length - 1]['time'] = formattedArrivalTime;
      }
    }
  }
  
  Future<void> refreshLocation() async {
    try {
      // First check the shared cache for updates
      if (_scheduleId > 0 && CommuterService.isSharedETAValid(_scheduleId)) {
        final sharedEta = CommuterService.getSharedETA(_scheduleId);
        if (busLocation['eta_minutes'] != sharedEta) {
          busLocation['eta_minutes'] = sharedEta;
          _updateTimesWithCurrentTime();
          notifyListeners();
        }
      }
      
      await _fetchLocationData();
      
      // Check if we should update the ETA
      final now = DateTime.now();
      if (now.difference(_lastEtaUpdate) >= _etaUpdateInterval && _scheduleId > 0) {
        await _updateETA();
        _lastEtaUpdate = now;
      }
    } catch (e) {
      print('Error refreshing location: $e');
    }
  }
  
  Future<void> _updateETA() async {
    if (_scheduleId <= 0) return;
    
    try {
      // Force a fresh ETA calculation
      await _commuterService.calculateETA(_scheduleId);
      
      // Get the updated ETA
      final eta = await _commuterService.getScheduleETA(_scheduleId);
      
      // Update the busLocation with the ETA
      busLocation['eta_minutes'] = eta;
      
      // Update times based on current time
      _updateTimesWithCurrentTime();
      
      notifyListeners();
    } catch (e) {
      print('Error updating ETA: $e');
    }
  }
  
  String _addMinutesToTime(String timeStr, int minutes) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final time = DateTime(2025, 1, 1, hour, minute);
    final newTime = time.add(Duration(minutes: minutes));
    
    return '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}';
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
  
  // Force an immediate ETA update
  Future<void> forceEtaUpdate() async {
    await _updateETA();
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

