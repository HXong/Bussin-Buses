import 'package:bussin_buses/services/commuter_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../pages/CommuterNav/seat_manager.dart';
import '../models/Booking.dart';
import '../models/Schedule.dart';

/// Main view model for commuter functionality
/// Manages bookings, schedules, ETAs, and user data
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
  
  // New property for ETA
  Map<int, int> scheduleETAs = {};
  
  /// Set of schedules for which ETA calculation is in progress
  /// Used to prevent duplicate API calls
  final Set<int> _etaCalculationInProgress = {};
  
  /// Checks if a booking has been canceled
  bool isCanceled(int bookingId) => _canceledBookings.contains(bookingId);
  
  /// Checks if a booking has been checked in
  bool isCheckIn(int bookingId) => _checkedInBookings.contains(bookingId);

  /// Gets the current user ID and fetches their bookings
  Future<void> obtainId() async {
    final id = _commuterService.getCommuterId();
    if (id != null) {
      await fetchBookings(id);
    }
  }

  /// Fetches upcoming bookings for a user
  /// Also fetches ETAs for the first few bookings
  Future<void> fetchBookings(String commuterId) async {
    isLoading = true;
    notifyListeners();

    try {
      bookings = await _commuterService.fetchUpcomingBookings(commuterId);
      
      /// Fetch ETAs for all bookings (but limit to avoid too many API calls)
      for (var i = 0; i < bookings.length && i < 3; i++) {
        final booking = bookings[i];
        if (booking.schedule != null) {
          // Extract schedule ID from the booking
          final scheduleId = getScheduleIdFromBooking(booking);
          
          /// Only fetch ETA if we don't already have it cached
          if (scheduleId > 0 && !scheduleETAs.containsKey(scheduleId)) {
            fetchETA(scheduleId);
          }
        }
      }
    } catch (e) {
      print('Error in ViewModel fetchBookings: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  /// Helper method to fetch ETA without blocking UI
  /// Uses a set to track in-progress calculations to avoid duplicate calls
  Future<void> fetchETA(int scheduleId) async {
    /// Skip if already calculating this ETA
    if (_etaCalculationInProgress.contains(scheduleId)) {
      return; // Already calculating
    }
    
    _etaCalculationInProgress.add(scheduleId);
    
    try {
      /// First check if the ETA is in the shared cache
      if (CommuterService.isSharedETAValid(scheduleId)) {
        scheduleETAs[scheduleId] = CommuterService.getSharedETA(scheduleId);
        notifyListeners();
      } else {
        /// If not in shared cache, fetch from service
        final eta = await _commuterService.getScheduleETA(scheduleId);
        scheduleETAs[scheduleId] = eta;
        // Update the shared cache
        CommuterService.updateSharedETA(scheduleId, eta);
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching ETA: $e');
    } finally {
      _etaCalculationInProgress.remove(scheduleId);
    }
  }

  /// Checks if a booking can be canceled based on time
  /// Returns true if the booking is at least 30 minutes in the future
  Future<bool> handleCancelWithTimeCheck(Booking booking) async {
    final schedule = booking.schedule;
    if (schedule == null) return false;

    try {
      /// Calculate the departure date and time
      final scheduleDateTime = DateTime.parse(schedule.date).add(
        Duration(
          hours: int.parse(schedule.time.split(':')[0]),
          minutes: int.parse(schedule.time.split(':')[1]),
        ),
      );
      final now = DateTime.now();
      /// Return true if departure is at least 30 minutes in the future
      return scheduleDateTime.difference(now) >= Duration(minutes: 30);
    } catch (_) {
      return false;
    }
  }

  /// Cancels a booking and updates the UI
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

  /// Checks in a booking and updates the UI
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

  /// Gets display details for a booking
  Map<String, String> getDisplayDetails(Booking booking) {
    return booking.displayDetails;
  }

  /// Loads schedule details for a specific schedule ID
  Future<void> loadSchedule(int scheduleId) async {
    final data = await _commuterService.fetchScheduleDetails(scheduleId);
    if (data == null) return;

    selectedSchedule = Schedule.fromMap(data);
    
    /// Get the ETA for this schedule
    fetchETA(scheduleId);
    
    notifyListeners();
  }

  /// Loads booked seats for a specific schedule
  Future<void> loadBookedSeats(int scheduleId) async {
    bookedSeats = await _commuterService.fetchBookedSeatNumbers(scheduleId);
    notifyListeners();
  }

  /// Confirms a seat booking for a schedule
  Future<String?> confirmBooking(int scheduleId, int seatNumber, String commuterId) async {
    try {
      final success = await _commuterService.confirmSeatBooking(
        scheduleId: scheduleId,
        seatNumber: seatNumber,
        commuterId: commuterId,
      );
      if (success) {
        bookedSeats.add(seatNumber.toString());
        /// Refresh bookings list after successful booking
        await fetchBookings(commuterId);
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Gets the number of available seats for a schedule
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
  
  /// Initializes data for the bus results screen
  /// Fetches location names, schedules, and ETAs
  Future<void> initializeBusResults() async {
    isLoading = true;
    notifyListeners();
    
    try {
      locationNames = await _commuterService.fetchLocationNames();
      schedules = await _commuterService.fetchAllSchedules();
      
      /// Filter schedules first
      filterSchedules(
        pickup: '', 
        destination: '', 
        date: ''
      );
      
      /// Only fetch ETAs for visible schedules to reduce API calls
      final visibleSchedules = filteredSchedules.take(5).toList(); // Limit to first 5 visible schedules
      
      for (var schedule in visibleSchedules) {
        final scheduleId = schedule['schedule_id'];
        if (scheduleId != null && !scheduleETAs.containsKey(scheduleId)) {
          fetchETA(scheduleId);
        }
      }
      
      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error initializing bus results: $e');
      isLoading = false;
      notifyListeners();
    }
  }
  
  /// Filters schedules based on pickup, destination, and date
  /// If showingAllSchedules is true, shows all schedules
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
      
      /// Match pickup, destination, and date if provided
      final pickupMatch = pickup.isEmpty || pickupName.toLowerCase().contains(pickup.toLowerCase());
      final destinationMatch = destination.isEmpty || destinationName.toLowerCase().contains(destination.toLowerCase());
      final dateMatch = date.isEmpty || schedule['date'].toString() == date;
      
      return pickupMatch && destinationMatch && dateMatch;
    }).toList();
    
    notifyListeners();
  }
  
  /// Toggles between showing all schedules and filtered schedules
  void toggleShowAllSchedules({required String pickup, required String destination, required String date}) {
    showingAllSchedules = !showingAllSchedules;
    filterSchedules(pickup: pickup, destination: destination, date: date);
  }
  
  /// Formats a date string to a more readable format
  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
  
  /// Adds minutes to a time string and returns the new time
  String addTimeToString(String timeStr, int minutes) {
    return _commuterService.addTimeToString(timeStr, minutes);
  }
  
  /// Gets the ETA for a specific schedule
  /// Checks shared cache, local cache, and fetches if needed
  int getETA(int scheduleId) {
    /// First check the shared cache
    if (CommuterService.isSharedETAValid(scheduleId)) {
      return CommuterService.getSharedETA(scheduleId);
    }
    
    /// Then check our local cache
    if (scheduleETAs.containsKey(scheduleId)) {
      return scheduleETAs[scheduleId]!;
    }
    
    /// If we don't have the ETA yet, trigger a fetch but return default value
    if (!_etaCalculationInProgress.contains(scheduleId)) {
      fetchETA(scheduleId);
    }
    
    return 30; // Default to 30 minutes while loading
  }
  
  /// Helper method to extract schedule ID from a booking
  int getScheduleIdFromBooking(Booking booking) {
    if (booking.schedule == null) return 0;
    
    /// Try to extract schedule ID from booking ID or other properties
    try {
      /// This is a guess - you may need to adjust based on your actual data structure
      final scheduleIdStr = booking.id.toString().split('_').last;
      return int.tryParse(scheduleIdStr) ?? 0;
    } catch (e) {
      print('Error extracting schedule ID: $e');
      return 0;
    }
  }
  
  /// Calculate arrival time based on departure time and ETA
  String calculateArrivalTime(String departureTime, int scheduleId) {
    final eta = getETA(scheduleId);
    return addTimeToString(departureTime, eta);
  }
  
  /// Initializes data for the home navigation screen
  Future<void> initializeHomeNav() async {
    isLoading = true;
    notifyListeners();
    
    try {
      /// Initialize with current date
      final now = DateTime.now();
      selectedDate = DateFormat('yyyy-MM-dd').format(now);
      
      /// Load user data and bookings
      await loadUserData();
      await loadUpcomingBookings();
    } catch (e) {
      print('Error initializing home nav: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  /// Loads user data including username
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
  
  /// Loads upcoming bookings for the current user
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
  
  /// Shows date picker and updates selected date
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
  
  /// Shows time picker and updates selected time
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