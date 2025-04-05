import 'package:bussin_buses/services/commuter_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  
  // New properties for BusResultsScreen
  List<Map<String, dynamic>> schedules = [];
  List<Map<String, dynamic>> filteredSchedules = [];
  Map<int, String> locationNames = {};
  bool showingAllSchedules = false;
  
  // New properties for HomeNav
  String? username;
  String selectedDate = '';
  String selectedTime = '';
  
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
        // Refresh bookings list after successful booking
        await fetchBookings(commuterId);
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<int> getAvailableSeatsCount(int scheduleId) async {
    try {
      final totalSeats = 25; // Assuming the bus has 25 seats total
      final bookedSeats = await _commuterService.fetchBookedSeatNumbers(scheduleId);
      return totalSeats - bookedSeats.length;
    } catch (e) {
      print('Error getting available seats count: $e');
      return 0;
    }
  }
  
  // Methods for BusResultsScreen
  Future<void> initializeBusResults() async {
    isLoading = true;
    notifyListeners();
    
    try {
      locationNames = await _commuterService.fetchLocationNames();
      schedules = await _commuterService.fetchAllSchedules();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error initializing bus results: $e');
      isLoading = false;
      notifyListeners();
    }
  }
  
  void filterSchedules({required String pickup, required String destination, required String date}) {
    if (showingAllSchedules) {
      filteredSchedules = schedules;
      notifyListeners();
      return;
    }
    
    filteredSchedules = schedules.where((schedule) {
      final pickupId = schedule['pickup'];
      final destinationId = schedule['destination'];
      
      final pickupName = locationNames[pickupId] ?? '';
      final destinationName = locationNames[destinationId] ?? '';
      
      final pickupMatch = pickupName.toLowerCase().contains(pickup.toLowerCase());
      final destinationMatch = destinationName.toLowerCase().contains(destination.toLowerCase());
      final dateMatch = schedule['date'].toString() == date;
      
      return pickupMatch && destinationMatch && dateMatch;
    }).toList();
    
    notifyListeners();
  }
  
  void toggleShowAllSchedules({required String pickup, required String destination, required String date}) {
    showingAllSchedules = !showingAllSchedules;
    filterSchedules(pickup: pickup, destination: destination, date: date);
  }
  
  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
  
  String addTimeToString(String timeStr, int minutes) {
    return _commuterService.addTimeToString(timeStr, minutes);
  }
  
  // New methods for HomeNav
  Future<void> initializeHomeNav() async {
    isLoading = true;
    notifyListeners();
    
    try {
      // Initialize with current date
      final now = DateTime.now();
      selectedDate = DateFormat('yyyy-MM-dd').format(now);
      
      // Load user data and bookings
      await loadUserData();
      await loadUpcomingBookings();
    } catch (e) {
      print('Error initializing home nav: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadUserData() async {
    try {
      final userId = _commuterService.getCommuterId();
      if (userId != null) {
        username = await _commuterService.fetchUsername(userId);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user data in ViewModel: $e');
    }
  }
  
  Future<void> loadUpcomingBookings() async {
    try {
      final commuterId = _commuterService.getCommuterId();
      if (commuterId != null) {
        await fetchBookings(commuterId);
      }
    } catch (e) {
      print('Error loading upcoming bookings in ViewModel: $e');
    }
  }
  
  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    
    if (picked != null) {
      selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      notifyListeners();
    }
  }
  
  Future<void> selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      selectedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      notifyListeners();
    }
  }
}