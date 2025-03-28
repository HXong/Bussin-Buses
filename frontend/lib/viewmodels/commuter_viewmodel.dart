import 'package:bussin_buses/services/commuter_service.dart';
import 'package:flutter/material.dart';
import '../pages/CommuterNav/seat_manager.dart';
import '../models/Booking.dart';
import '../models/Schedule.dart';

class CommuterViewModel extends ChangeNotifier {
  CommuterViewModel(this._commuterService);
  final CommuterService _commuterService;
  final Set<int> _canceledBookings = {};
  final Set<int> _checkedInBookings = {};
  List<Booking> bookings = [];
  List<String> bookedSeats = [];
  Schedule? selectedSchedule;
  bool isLoading = false;
  bool isCanceled(int bookingId) => _canceledBookings.contains(bookingId);
  bool isCheckIn(int bookingId) => _checkedInBookings.contains(bookingId);



  Future<void> obtainId() async {
    final id = _commuterService.getCommuterId();
    if (id != null) {
      await fetchBookings(id);
    }
  }

  Future<void> fetchBookings(String commuterId) async {
    isLoading = true;
    notifyListeners();

    try {
      bookings = await _commuterService.fetchUpcomingBookings(commuterId);
    } catch (e) {
      print('Error in ViewModel fetchBookings: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> handleCancelWithTimeCheck(Booking booking) async {
    final schedule = booking.schedule;
    if (schedule == null) return false;

    try {
      final scheduleDateTime = DateTime.parse(schedule.date).add(
        Duration(
          hours: int.parse(schedule.time.split(':')[0]),
          minutes: int.parse(schedule.time.split(':')[1]),
        ),
      );
      final now = DateTime.now();
      return scheduleDateTime.difference(now) >= Duration(minutes: 30);
    } catch (_) {
      return false;
    }
  }

  Future<String?> cancelBooking(Booking booking) async {
    final bookingId = booking.id;
    try {
      await _commuterService.cancelBooking(bookingId);
      await seatManager.loadBookedSeats();
      _canceledBookings.add(bookingId);
      notifyListeners();
      return null;
    } catch (_) {
      return "Cancellation failed. Try again.";
    }
  }

  Future<String?> checkIn(Booking booking) async {
    try {
      await _commuterService.checkInBooking(booking.id);
      _checkedInBookings.add(booking.id);
      notifyListeners();
      return null;
    } catch (_) {
      return "Check IN failed. Try again.";
    }
  }

  Map<String, String> getDisplayDetails(Booking booking) {
    return booking.displayDetails;
  }

  Future<void> loadSchedule(int scheduleId) async {
    final data = await _commuterService.fetchScheduleDetails(scheduleId);
    if (data == null) return;

    selectedSchedule = Schedule.fromMap(data);
    notifyListeners();
  }

  Future<void> loadBookedSeats(int scheduleId) async {
    bookedSeats = await _commuterService.fetchBookedSeatNumbers(scheduleId);
    notifyListeners();
  }

  Future<String?> confirmBooking(int scheduleId, int seatNumber, String commuterId) async {
    try {
      final success = await _commuterService.confirmSeatBooking(
        scheduleId: scheduleId,
        seatNumber: seatNumber,
        commuterId: commuterId,
      );
      if (success) {
        bookedSeats.add(seatNumber.toString());
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
