import 'dart:async';
import 'package:bussin_buses/models/DriverProfile.dart';
import 'package:flutter/material.dart';
import '../services/driver_service.dart';
import '../services/supabase_client_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverViewModel extends ChangeNotifier {
  final DriverService _driverService;
  final SupabaseClient _supabase = SupabaseClientService.client;

  DriverProfile? driverProfile;

  int selectedIndex = 0;

  bool isLoading = false;

  final TextEditingController feedbackController = TextEditingController();
  final timeNow = DateTime.now().toUtc().add(const Duration(hours: 8));

  DriverViewModel(this._driverService) {
    fetchPersonalInformation();
  }

  Future<void> fetchPersonalInformation() async {
    isLoading = true;
    notifyListeners();
    final driverId = _supabase.auth.currentUser?.id;

    if (driverId == null) {
      print('Driver ID is null');
      return;
    }

    try {
      final profileData = await _driverService.fetchDriverProfile(driverId);
      driverProfile = DriverProfile.fromMap(profileData);
      notifyListeners();

    } catch (e) {
      print('Error fetching personal information: $e');
    }
    isLoading = false;
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

  @override
  void dispose() {
    _driverService.dispose();
    super.dispose();
  }
}