import 'package:bussin_buses/services/commuter_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../pages/CommuterNav/seat_manager.dart';

class ScheduleDisplayData {
  final String pickup;
  final String destination;
  final String date;
  final String time;

  ScheduleDisplayData({
    required this.pickup,
    required this.destination,
    required this.date,
    required this.time,
  });
}

class BookingDetails {
  final String pickup;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String seatNumber;
  final String scheduleDate;

  BookingDetails({
    required this.pickup,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.seatNumber,
    required this.scheduleDate,
  });
}


class CommuterViewModel extends ChangeNotifier {
  final CommuterService _commuterService;
  final Set<dynamic> _canceledBookings = {};
  final Set<dynamic> _checkedInBookings = {};

  bool isCanceled(dynamic bookingId) => _canceledBookings.contains(bookingId);
  bool isCheckIn(dynamic bookingId) => _checkedInBookings.contains(bookingId);


  CommuterViewModel(this._commuterService);

  List<Map<String, dynamic>> bookings = [];
  List<String> bookedSeats = [];
  ScheduleDisplayData? scheduleData;
  bool isLoading = false;

  Future<void> fetchBookings() async {
    isLoading = true;
    notifyListeners();

    try {
      bookings = await _commuterService.fetchUpcomingBookings();
    } catch (e) {
      print('Error in ViewModel fetchBookings: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> handleCancelWithTimeCheck(Map<String, dynamic> booking) async {
    final departureTimeRaw = booking['schedule_id']?['time']?.toString();
    final scheduleDateRaw = booking['schedule_id']?['date'];

    if (departureTimeRaw == null || scheduleDateRaw == null) {
      return false;
    }

    try {
      final parts = departureTimeRaw.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final scheduleDateTime = DateTime.parse(scheduleDateRaw)
          .add(Duration(hours: hour, minutes: minute));

      final now = DateTime.now();

      if (scheduleDateTime.difference(now) < Duration(minutes: 30)) {
        return false;
      } else {
        return true;
      }
    } catch (_) {
      return false;
    }
  }

  Future<String?> cancelBooking(Map<String, dynamic> booking) async {
    final rawBookingId = booking['booking_id'];
    final bookingId = int.tryParse(rawBookingId.toString());
    if (bookingId == null) return "Invalid booking ID";

    try {
      await _commuterService.cancelBooking(bookingId);
      await seatManager.loadBookedSeats();
      _canceledBookings.add(bookingId);
      notifyListeners();
      return null;
    } catch (e) {
      return "Cancellation failed. Try again.";
    }
  }

  Future<String?> checkIn(Map<String, dynamic> booking) async {
    final bookingId = booking['booking_id'];
    if (bookingId == null) return "Check-in failed: Missing booking ID.";

    try {
      await _commuterService.checkInBooking(bookingId);
      _checkedInBookings.add(bookingId);
      notifyListeners();
      return null;
    } catch (e) {
      return "Check IN failed. Try again.";
    }
  }

  BookingDetails getDisplayDetails(Map<String, dynamic> booking) {
    final pickup = booking['schedule_id']?['pickup']?['location_name'] ?? 'N/A';
    final destination = booking['schedule_id']?['destination']?['location_name'] ?? 'N/A';
    final departureTimeRaw = booking['schedule_id']?['time']?.toString();
    final departureTime = (departureTimeRaw != null && departureTimeRaw.contains(':'))
        ? departureTimeRaw.substring(0, 5)
        : 'N/A';
    final arrivalTime = 'TBA';
    final seatNumber = booking['seat_id']?['seat_number']?.toString() ?? 'N/A';

    String scheduleDate = 'Date Unknown';
    final rawDate = booking['schedule_id']?['date'];
    if (rawDate != null) {
      try {
        final parsed = DateTime.parse(rawDate);
        scheduleDate = DateFormat('dd MMM, yyyy').format(parsed).toUpperCase();
      } catch (_) {}
    }

    return BookingDetails(
      pickup: pickup,
      destination: destination,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      seatNumber: seatNumber,
      scheduleDate: scheduleDate,
    );
  }

  Future<void> loadSchedule(int scheduleId) async {
    final data = await _commuterService.fetchScheduleDetails(scheduleId);
    if (data == null) return;

    final pickup = data['pickup']?['location_name'] ?? 'N/A';
    final destination = data['destination']?['location_name'] ?? 'N/A';
    final rawDate = data['date'];
    final rawTime = data['time']?.toString();

    String dateFormatted = 'Unknown Date';
    String timeFormatted = 'Unknown Time';

    if (rawDate != null) {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        dateFormatted = DateFormat('EEE, dd MMM yyyy').format(parsed);
      }
    }

    if (rawTime != null && rawTime.contains(':')) {
      final parts = rawTime.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final parsed = DateTime(2025, 1, 1, hour, minute);
      timeFormatted = DateFormat('HH:mm').format(parsed);
    }

    scheduleData = ScheduleDisplayData(
      pickup: pickup,
      destination: destination,
      date: dateFormatted,
      time: timeFormatted,
    );
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