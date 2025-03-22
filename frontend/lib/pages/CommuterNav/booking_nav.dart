import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'seat_manager.dart';  // Import the SeatManager class


class BookingNav extends StatefulWidget {
  const BookingNav({super.key});

  @override
  State<BookingNav> createState() => _BookingNavState();
}

class _BookingNavState extends State<BookingNav> {
  List<String> bookedSeats = seatManager.bookedSeats;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "NTU - Tampines",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: 8),
          Text(
            "Tue 20 Jan 2025 | 17:00",
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          SizedBox(height: 16),
          Text(
            "Choose Your Seat",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          // Seat Selection Box
          Expanded(
            child: Center(
              child: Container(
                padding: EdgeInsets.all(16),
                width: 250,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // First Row (5 Seats)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        5,
                            (index) => seatIcon("A${index + 1}"),
                      ),
                    ),
                    SizedBox(height: 10),

                    // Remaining Rows (5 rows excluding the first row)
                    Expanded(
                      child: ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: 5,
                        itemBuilder: (context, rowIndex) {
                          String rowLetter = String.fromCharCode(66 + rowIndex); // Generates B, C, D, E, F

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                seatIcon("$rowLetter${1}"),
                                seatIcon("$rowLetter${2}"),
                                SizedBox(width: 40),
                                seatIcon("$rowLetter${3}"),
                                seatIcon("$rowLetter${4}"),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Generates a seat icon with label and checks if it's booked
  Widget seatIcon(String seatLabel) {
    bool isBooked = bookedSeats.contains(seatLabel); // Check if seat is already booked

    return Column(
      children: [
        GestureDetector(
          onTap: isBooked
              ? null // Disable click if seat is booked
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailScreen(
                  booking: {
                    'seat': seatLabel,
                    'departure': '17:00',
                    'arrival': '18:15',
                    'pickup': 'NTU',
                    'destination': 'Tampines',
                    'date': '20 Jan, 2025',
                  },
                  bookedSeats: bookedSeats, // Pass the list of booked seats
                ),
              ),
            ).then((value) {
              if (value == true) {
                setState(() {}); // Refresh UI after booking
              }
            });
          },
          child: Icon(
            Icons.event_seat,
            size: 25,
            color: isBooked ? Colors.red : Colors.black54, // Highlight booked seats in red
          ),
        ),
        SizedBox(height: 4),
        Text(
          seatLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isBooked ? Colors.red : Colors.black, // Change text color for booked seats
          ),
        ),
      ],
    );
  }
}

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final List<String> bookedSeats; // Pass booked seats from BookingNav

  BookingDetailScreen({required this.booking, required this.bookedSeats});

  @override
  _BookingDetailScreenState createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool isConfirm = false;

  /// Confirms the booking and updates the local booked seats list
  void confirmBooking() {
    // Check if the seat is already booked before adding
    if (widget.bookedSeats.contains(widget.booking['seat'])) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seat already booked!')),
      );
      return;
    }
    if (!seatManager.bookedSeats.contains(widget.booking['seat'])) {
      seatManager.bookedSeats.add(widget.booking['seat']); // Add seat to global list
    }

    setState(() {
      isConfirm = true; // Show "Booking Confirmed" overlay
    });

    // Add seat to the booked seats list
    widget.bookedSeats.add(widget.booking['seat']);
  }

  /// Exits the screen and sends `true` back to refresh the list
  void exitScreen() {
    Navigator.pop(context, true); // Sends "true" to refresh booked seats in BookingNav
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isConfirm ? exitScreen : null, // Tap anywhere to exit after confirmation
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Booking Detail",
            style: TextStyle(color: isConfirm ? Colors.black38 : Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Booking Details Card
            Opacity(
              opacity: isConfirm ? 0.3 : 1, // Dim background when confirmed
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Booking Confirmation",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isConfirm ? Colors.black26 : Colors.black,
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
                          SizedBox(height: 40),
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
                            onPressed: isConfirm ? null : confirmBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[500],
                              minimumSize: Size(double.infinity, 45),
                            ),
                            child: Text("Confirm Booking", style: TextStyle(color: Colors.black)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Booking Confirm Overlay
            if (isConfirm)
              Container(
                color: Colors.black.withOpacity(0.2),
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
                      child: Text("Booking Confirmed", textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
