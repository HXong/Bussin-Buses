import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//use the list first, when combine with other UI then use this fuctions
/*class TicketNav extends StatefulWidget {
  @override
  _TicketNavState createState() => _TicketNavState();
}

class _TicketNavState extends State<TicketNav> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    try {
      final response = await supabase.from('bookings').select(); // Fetch all bookings
      setState(() {
        bookings = response.map((data) => data as Map<String, dynamic>).toList();
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching bookings: $error");
      setState(() {
        isLoading = false;
      });
    }
  }*/


class TicketNav extends StatelessWidget {
  final List<Map<String, dynamic>> bookings = [
    {
      "date": "20 JAN, 2025",
      "pickup": "NTU",
      "departure": "17:00",
      "destination": "TAMPINES",
      "arrival": "18:15",
      "seat": "C1",
      "busNumber": "SMB123S"
    },
    {
      "date": "22 JAN, 2025",
      "pickup": "NTU",
      "departure": "17:00",
      "destination": "TAMPINES",
      "arrival": "18:15",
      "seat": "D3",
      "busNumber": "SMB123S"
    },
    {
      "date": "24 JAN, 2025",
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingDetailScreen(booking: booking),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text("Details", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  BookingDetailScreen({required this.booking});

  @override
  _BookingDetailScreenState createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool isCanceled = false;
  bool isCheckIn = false;

  /// Handles Check-In
  void checkInBooking() async {
    setState(() {
      isCheckIn = true;
    });
  }

  /// Handles Cancel Booking
  void cancelBooking() async {
    setState(() {
      isCanceled = true;
    });
  }

  /// Exits the screen when **either** action is completed
  void exitScreen() {
    if (isCanceled || isCheckIn) {
      Navigator.pop(context, true); // Ensures the UI updates
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (isCanceled || isCheckIn) ? exitScreen : null, // Tap anywhere to exit
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Booking Detail",
            style: TextStyle(color: (isCanceled || isCheckIn) ? Colors.black38 : Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // 🔹 Dim Background if booking is canceled or checked in
            Opacity(
              opacity: (isCanceled || isCheckIn) ? 0.3 : 1,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Booking Detail",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: (isCanceled || isCheckIn) ? Colors.black26 : Colors.black,
                      ),
                    ),
                    SizedBox(height: 20),

                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${widget.booking['date']}",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Pickup", style: TextStyle(fontSize: 14, color: Colors.black54)),
                                  Text("${widget.booking['pickup']}",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("Departure", style: TextStyle(fontSize: 14, color: Colors.black54)),
                                  Text("${widget.booking['departure']}",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Destination", style: TextStyle(fontSize: 14, color: Colors.black54)),
                                  Text("${widget.booking['destination']}",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("Arrival", style: TextStyle(fontSize: 14, color: Colors.black54)),
                                  Text("~${widget.booking['arrival']}",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 30),

                          Row(
                            children: [
                              Icon(Icons.person, size: 20),
                              SizedBox(width: 4),
                              Text("1", style: TextStyle(fontSize: 14)),
                              SizedBox(width: 10),
                              Icon(Icons.event_seat, size: 20),
                              SizedBox(width: 4),
                              Text("${widget.booking['seat']}",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 40),

                          ElevatedButton(
                            onPressed: isCheckIn ? null : checkInBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[400],
                              minimumSize: Size(double.infinity, 45),
                            ),
                            child: Text("Check In", style: TextStyle(color: Colors.black)),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: isCanceled ? null : cancelBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[400],
                              minimumSize: Size(double.infinity, 45),
                            ),
                            child: Text("Cancel Booking", style: TextStyle(color: Colors.black)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 Check-In Overlay (Same Style as Cancel)
            if (isCheckIn)
              overlayMessage("Checked In"),

            // 🔹 Cancel Booking Overlay (Same Style as Check-In)
            if (isCanceled)
              overlayMessage("Booking Canceled"),
          ],
        ),
      ),
    );
  }

  /// 🔹 Extracted Overlay UI for Reusability
  Widget overlayMessage(String message) {
    return Container(
      color: Colors.black.withOpacity(0.2), // Semi-transparent overlay
      child: Center(
        child: Container(
          width: 280,
          height: 270,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[350],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}




