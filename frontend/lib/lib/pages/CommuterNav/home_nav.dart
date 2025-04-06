// lib/pages/CommuterNav/home_nav.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/commuter_viewmodel.dart';
import '../../models/Booking.dart';

class HomeNav extends StatefulWidget {
  final void Function(int)? onScheduleSelected;
  final void Function(String, String, String, String)? onSearchSubmitted;
  final void Function()? onUpcomingBookingTap;
  
  const HomeNav({
    this.onScheduleSelected, 
    this.onSearchSubmitted,
    this.onUpcomingBookingTap,
    super.key
  });

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  final TextEditingController pickupController = TextEditingController(text: 'NTU');
  final TextEditingController destinationController = TextEditingController(text: 'Tampines');

  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    final viewModel = Provider.of<CommuterViewModel>(context, listen: false);
    await viewModel.initializeHomeNav();
  }

  void _findBus() {
    if (widget.onSearchSubmitted != null) {
      final viewModel = Provider.of<CommuterViewModel>(context, listen: false);
      widget.onSearchSubmitted!(
        pickupController.text,
        destinationController.text,
        viewModel.selectedDate,
        viewModel.selectedTime.isEmpty ? '' : viewModel.selectedTime,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CommuterViewModel>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Text(
                "Welcome Back${viewModel.username != null ? '\n${viewModel.username}' : ''}",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Search form
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Search",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Pickup field
                    const Text(
                      "Pick-up",
                      style: TextStyle(fontSize: 14),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Icon(Icons.location_on, size: 20),
                          ),
                          Expanded(
                            child: TextField(
                              controller: pickupController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Destination field
                    const Text(
                      "Destination",
                      style: TextStyle(fontSize: 14),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Icon(Icons.location_on, size: 20),
                          ),
                          Expanded(
                            child: TextField(
                              controller: destinationController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Date and Time
                    Row(
                      children: [
                        // Date picker
                        Expanded(
                          child: InkWell(
                            onTap: () => viewModel.selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  viewModel.selectedDate.isEmpty 
                                      ? "Date" 
                                      : DateFormat('dd MMM yyyy').format(DateTime.parse(viewModel.selectedDate)),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Time picker
                        Expanded(
                          child: InkWell(
                            onTap: () => viewModel.selectTime(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  viewModel.selectedTime.isEmpty ? "Time" : viewModel.selectedTime,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Find bus button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _findBus,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[400],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Find your bus",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Upcoming bookings
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Upcoming Booking",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    viewModel.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : viewModel.bookings.isEmpty
                            ? const Center(
                                child: Text(
                                  "No upcoming bookings",
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            : Column(
                                children: viewModel.bookings.take(3).map((booking) {
                                  final schedule = booking.schedule;
                                  if (schedule == null) return const SizedBox.shrink();
                                  
                                  // Parse date
                                  DateTime? date;
                                  try {
                                    date = DateTime.parse(schedule.date);
                                  } catch (_) {}
                                  
                                  // Get schedule ID from booking
                                  final scheduleId = viewModel.getScheduleIdFromBooking(booking);
                                  
                                  // Get ETA for this schedule
                                  final eta = viewModel.getETA(scheduleId);
                                  final arrivalTime = viewModel.calculateArrivalTime(schedule.time, scheduleId);
                                  
                                  return InkWell(
                                    onTap: () {
                                      if (widget.onUpcomingBookingTap != null) {
                                        widget.onUpcomingBookingTap!();
                                      }
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[400],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          // Date
                                          Container(
                                            width: 50,
                                            child: Column(
                                              children: [
                                                Text(
                                                  date != null ? date.day.toString() : "--",
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  date != null 
                                                      ? DateFormat('MMM').format(date).toUpperCase() 
                                                      : "---",
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Time and route
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        schedule.time.substring(0, 5),
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        "${eta}m",
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        arrivalTime.substring(0, 5),
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        schedule.pickup,
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        schedule.destination,
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          
                                          // Arrow
                                          const Icon(Icons.arrow_forward_ios, size: 16),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}