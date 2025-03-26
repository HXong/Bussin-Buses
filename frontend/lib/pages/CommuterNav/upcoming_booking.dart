import 'package:bussin_buses/pages/CommuterNav/ticket_nav.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'booking_detail_screen.dart';

class BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final scheduleTimeRaw = booking['schedule_id']?['time']?.toString();
    final pickup = booking['schedule_id']?['pickup']?['location_name'] ?? 'N/A';
    final destination = booking['schedule_id']?['destination']?['location_name'] ?? 'N/A';
    final seatNumber = booking['seat_id']?['seat_number']?.toString() ?? 'N/A';
    final scheduleDateRaw = booking['schedule_id']?['date'];
    String departureTime = 'N/A';
    String arrivalTime = 'N/A';
    String scheduleDate = 'N/A';

    if (scheduleDateRaw != null) {
      try {
        final parsedDate = DateTime.parse(scheduleDateRaw);
        scheduleDate = DateFormat('dd MMM, yyyy').format(parsedDate).toUpperCase();
      } catch (e) {
        print("Date parsing error: $e");
      }
    }

    if (scheduleTimeRaw != null && scheduleTimeRaw.contains(':')) {
      try {
        final parts = scheduleTimeRaw.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final departureDateTime = DateTime(2025, 1, 20, hour, minute);
        final arrivalDateTime = departureDateTime.add(Duration(hours: 1, minutes: 15));
        departureTime = DateFormat('HH:mm').format(departureDateTime);
        arrivalTime = DateFormat('HH:mm').format(arrivalDateTime);

      } catch (e) {
        print("Time calculation error: $e");
      }
    }

    return Card(
      color: Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$scheduleDate • Provided by Busin Buses",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16),
                          SizedBox(width: 4),
                          Text(pickup, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Text(departureTime, style: TextStyle(fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text("1h 15m", style: TextStyle(fontSize: 14, color: Colors.black54)),
                    Icon(Icons.directions_bus, size: 20),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.location_on, size: 16),
                          SizedBox(width: 4),
                          Text(destination, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Text(arrivalTime, style: TextStyle(fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 16),
                    SizedBox(width: 4),
                    Text("1", style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Icon(Icons.event_seat, size: 16),
                    SizedBox(width: 4),
                    Text(seatNumber, style: TextStyle(fontSize: 14)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.directions_bus, size: 16),
                    SizedBox(width: 4),
                    Text("SMB123S", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Icon(Icons.info_outline, size: 16, color: Colors.black54),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            booking['is_checked_in'] == true
                ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Checked In",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text("Details", style: TextStyle(color: Colors.white)),
                ),
              ],
            )

          ],
        ),
      ),
    );
  }
}
