import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/commuter_viewmodel.dart';
import './booking_nav.dart';

class BusResultsScreen extends StatefulWidget {
  final String pickup;
  final String destination;
  final String date;
  final Function(int) onScheduleSelected;
  
  const BusResultsScreen({
    required this.pickup,
    required this.destination,
    required this.date,
    required this.onScheduleSelected,
    Key? key,
  }) : super(key: key);

  @override
  State<BusResultsScreen> createState() => _BusResultsScreenState();
}

class _BusResultsScreenState extends State<BusResultsScreen> {
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    final viewModel = Provider.of<CommuterViewModel>(context, listen: false);
    await viewModel.initializeBusResults();
    viewModel.filterSchedules(
      pickup: widget.pickup,
      destination: widget.destination,
      date: widget.date
    );
  }
  
  void _navigateToBooking(int scheduleId) {
    // First call the onScheduleSelected callback to update the parent state
    widget.onScheduleSelected(scheduleId);
    
    // Then navigate directly to the BookingNav screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingNav(scheduleId: scheduleId),
      ),
    );
  }
  
  String _getMonthAbbreviation(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM').format(date).toUpperCase();
    } catch (_) {
      return "---";
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CommuterViewModel>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              viewModel.showingAllSchedules 
                  ? "All Bus Schedules" 
                  : "${widget.pickup} - ${widget.destination}",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!viewModel.showingAllSchedules)
              Text(
                _formatDate(widget.date),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 16),
            
            // Toggle button
            ElevatedButton(
              onPressed: () => viewModel.toggleShowAllSchedules(
                pickup: widget.pickup,
                destination: widget.destination,
                date: widget.date
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                viewModel.showingAllSchedules ? "Show Filtered Results" : "Show All Schedules",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.filteredSchedules.isEmpty
                    ? const Center(
                        child: Text(
                          "No schedules available for this route and date",
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: viewModel.filteredSchedules.length,
                          itemBuilder: (context, index) {
                            final schedule = viewModel.filteredSchedules[index];
                            
                            // Ensure schedule_id is an int.
                            final int scheduleId = schedule['schedule_id'] is int
                                ? schedule['schedule_id']
                                : int.tryParse(schedule['schedule_id'].toString()) ?? 0;
                            
                            // Convert time and date fields to string.
                            final timeField = schedule['time'].toString();
                            final timeStr = timeField.contains(':') 
                                ? timeField.substring(0, 5) 
                                : timeField;
                            final arrivalTime = viewModel.addTimeToString(timeField, 75);
                            
                            // Convert date to string.
                            final date = schedule['date'].toString();
                            final monthAbbreviation = _getMonthAbbreviation(date);
                            
                            // Get location names from the IDs
                            final pickupId = schedule['pickup'];
                            final destinationId = schedule['destination'];
                            final pickupName = viewModel.locationNames[pickupId] ?? 'Unknown';
                            final destinationName = viewModel.locationNames[destinationId] ?? 'Unknown';
                            
                            return FutureBuilder<int>(
                              future: viewModel.getAvailableSeatsCount(scheduleId),
                              builder: (context, snapshot) {
                                final availableSeats = snapshot.data ?? 0;
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      // Date column
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          children: [
                                            Text(
                                              date.substring(8, 10),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              monthAbbreviation,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Divider
                                      Container(
                                        width: 1,
                                        height: 80,
                                        color: Colors.grey[400],
                                      ),
                                      
                                      // Schedule details
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    timeStr,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const Text(
                                                    "1h 15m",
                                                    style: TextStyle(fontSize: 14),
                                                  ),
                                                  Text(
                                                    arrivalTime,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    pickupName,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  Text(
                                                    destinationName,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      
                                      // Seats and book button
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  "$availableSeats",
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(Icons.event_seat, size: 16),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            ElevatedButton(
                                              onPressed: () => _navigateToBooking(scheduleId),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.pink[300],
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              ),
                                              child: const Text(
                                                "Book",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEE dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}