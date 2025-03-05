import 'package:flutter/material.dart';

class TicketNav extends StatelessWidget {
  final List<Map<String, dynamic>> bookings = [
    {
      "date": "20 JAN",
      "pickup": "NTU",
      "departure": "17:00",
      "destination": "TAMPINES",
      "arrival": "18:15",
      "seat": "C1",
      "busNumber": "SMB123S"
    },
    {
      "date": "22 JAN",
      "pickup": "NTU",
      "departure": "17:00",
      "destination": "TAMPINES",
      "arrival": "18:15",
      "seat": "D3",
      "busNumber": "SMB123S"
    },
    {
      "date": "24 JAN",
      "pickup": "NTU",
      "departure": "17:00",
      "destination": "TAMPINES",
      "arrival": "18:15",
      "seat": "F4",
      "busNumber": "SMB123S"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Upcoming Bookings", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return BookingCard(
              booking: booking,
            );
          },
        ),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;

  BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${booking['date']}  •  Provided by Busin Buses", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            SizedBox(height: 8),

            // 🔹 Pickup and Destination Information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16),
                        SizedBox(width: 4),
                        Text("${booking['pickup']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Text("${booking['departure']}", style: TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("1h 15m", style: TextStyle(fontSize: 14, color: Colors.black54)),
                    Icon(Icons.directions_bus, size: 20),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16),
                        SizedBox(width: 4),
                        Text("${booking['destination']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Text("~${booking['arrival']}", style: TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
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
                    Text("1", style: TextStyle(fontSize: 14)), // Assuming 1 passenger
                    SizedBox(width: 8),
                    Icon(Icons.event_seat, size: 16),
                    SizedBox(width: 4),
                    Text("${booking['seat']}", style: TextStyle(fontSize: 14)), // Display Seat Number
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.directions_bus, size: 16),
                    SizedBox(width: 4),
                    Text("${booking['busNumber']}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Icon(Icons.info_outline, size: 16, color: Colors.black54),
                  ],
                ),
              ],
            ),

            SizedBox(height: 12),

            // 🔹 Buttons (Check-In & Cancel)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text("Check In", style: TextStyle(color: Colors.white)),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingDetailScreen(booking: booking),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class BookingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  BookingDetailScreen({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Booking Detail")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${booking['date']} - ${booking['pickup']} to ${booking['destination']}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Seat: ${booking['seat']}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Confirm Cancellation"),
            ),
          ],
        ),
      ),
    );
  }
}
