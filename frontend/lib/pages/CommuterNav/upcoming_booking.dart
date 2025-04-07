// lib/pages/CommuterNav/upcoming_booking.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bussin_buses/models/Booking.dart';
import 'package:bussin_buses/pages/CommuterNav/booking_detail_screen.dart';
import 'package:bussin_buses/pages/CommuterNav/ticket_nav.dart';
import 'package:bussin_buses/viewmodels/commuter_viewmodel.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final Function(int)? onViewLiveLocation;
  
  const BookingCard({
    required this.booking,
    this.onViewLiveLocation,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CommuterViewModel>(context);
    final schedule = booking.schedule;
    final pickup = schedule?.pickup ?? 'N/A';
    final destination = schedule?.destination ?? 'N/A';
    final seatNumber = booking.seatNumber ?? 'N/A';

    String departureTime = 'N/A';
    String arrivalTime = 'N/A';
    String scheduleDate = 'N/A';
    
    // Extract schedule ID from booking
    final scheduleId = viewModel.getScheduleIdFromBooking(booking);
    
    // Get ETA for this schedule
    final etaMinutes = viewModel.getETA(scheduleId);
    
    // Format ETA as hours and minutes
    final etaHours = etaMinutes ~/ 60;
    final etaRemainingMinutes = etaMinutes % 60;
    final etaFormatted = etaHours > 0 
        ? "${etaHours}h ${etaRemainingMinutes}m" 
        : "${etaRemainingMinutes}m";

    if (schedule != null) {
      try {
        final parsedDate = DateTime.parse(schedule.date);
        scheduleDate = DateFormat('dd MMM, yyyy').format(parsedDate).toUpperCase();

        final parts = schedule.time.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final departureDateTime = DateTime(2025, 1, 20, hour, minute);
        
        // Calculate arrival time using the dynamic ETA
        final arrivalDateTime = departureDateTime.add(Duration(minutes: etaMinutes));

        departureTime = DateFormat('HH:mm').format(departureDateTime);
        arrivalTime = DateFormat('HH:mm').format(arrivalDateTime);
      } catch (e) {
        print("Time/date parsing error: $e");
      }
    }

    return Card(
      color: Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$scheduleDate • Provided by Busin Buses",
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Text(pickup, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Text(departureTime, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(etaFormatted, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    const Icon(Icons.directions_bus, size: 20),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Text(destination, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Text(arrivalTime, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 4),
                    const Text("1", style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    const Icon(Icons.event_seat, size: 16),
                    const SizedBox(width: 4),
                    Text(seatNumber, style: const TextStyle(fontSize: 14)),
                  ],
                ),
                Row(
                  children: const [
                    Icon(Icons.directions_bus, size: 16),
                    SizedBox(width: 4),
                    Text("SMB123S", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Icon(Icons.info_outline, size: 16, color: Colors.black54),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            booking.isCheckedIn
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Checked In",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (onViewLiveLocation != null) {
                            onViewLiveLocation!(booking.id);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text("Live Location", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingDetailScreen(booking: booking),
                            ),
                          );
                          if (result == true) {
                            final state = context.findAncestorStateOfType<TicketNavState>();
                            state?.fetchBookings();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text("Details", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

