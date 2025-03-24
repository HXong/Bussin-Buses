import 'package:flutter/foundation.dart';
import '../services/commuter_service.dart';

class CommuterViewModel extends ChangeNotifier {
  final CommuterService _service;
  Map<String, dynamic>? _userProfile;

  CommuterViewModel(this._service);

  // User profile methods
  Future<Map<String, dynamic>> getUserProfile() async {
    if (_userProfile != null) {
      return _userProfile!;
    }

    _userProfile = await _service.getUserProfile();
    return _userProfile!;
  }

  Future<void> updateUserProfile({
    required String fullName,
    required String phone,
    String? profilePicture,
  }) async {
    await _service.updateUserProfile(
      fullName: fullName,
      phone: phone,
      profilePicture: profilePicture,
    );

    // Update the cached profile
    if (_userProfile != null) {
      _userProfile!['full_name'] = fullName;
      _userProfile!['phone'] = phone;
      if (profilePicture != null) {
        _userProfile!['avatar_url'] = profilePicture;
      }
    }

    notifyListeners();
  }

  Future<void> signOut() async {
    await _service.signOut();
    _userProfile = null;
    notifyListeners();
  }

  // Bus search and booking methods
  Future<List<Map<String, dynamic>>> searchBuses({
    required String from,
    required String to,
    required DateTime date,
  }) async {
    return await _service.searchBuses(
      from: from,
      to: to,
      date: date,
    );
  }

  Future<Map<String, dynamic>> getBusDetails(String busId) async {
    return await _service.getBusDetails(busId);
  }

  Future<Map<String, dynamic>> bookBus({
    required String busId,
    required String seatNumber,
    required String passengerName,
    required String passengerEmail,
    required String passengerPhone,
  }) async {
    final result = await _service.bookBus(
      busId: busId,
      seatNumber: seatNumber,
      passengerName: passengerName,
      passengerEmail: passengerEmail,
      passengerPhone: passengerPhone,
    );
    notifyListeners();
    return result;
  }

  // Booking management methods
  Future<List<Map<String, dynamic>>> getUpcomingBookings() async {
    return await _service.getUpcomingBookings();
  }

  Future<Map<String, dynamic>> getBookingDetails(String bookingId) async {
    return await _service.getBookingDetails(bookingId);
  }

  Future<bool> cancelBooking(String bookingId) async {
    final result = await _service.cancelBooking(bookingId);
    notifyListeners();
    return result;
  }

  Future<void> checkInBooking(String bookingId) async {
    await _service.checkInBooking(bookingId);
    notifyListeners();
  }
}

