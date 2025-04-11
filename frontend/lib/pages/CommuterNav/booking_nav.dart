import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bussin_buses/viewmodels/commuter_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen for selecting seats and making bookings
class BookingNav extends StatefulWidget {
  final int scheduleId;
  const BookingNav({super.key, required this.scheduleId});

  @override
  State<BookingNav> createState() => _BookingNavState();
}

class _BookingNavState extends State<BookingNav> {
  @override
  void initState() {
    super.initState();
    /// Load schedule and booked seats data when screen initializes
    final commuterVM = Provider.of<CommuterViewModel>(context, listen: false);
    commuterVM.loadSchedule(widget.scheduleId);
    commuterVM.loadBookedSeats(widget.scheduleId);
  }

  @override
  Widget build(BuildContext context) {
    final commuterVM = Provider.of<CommuterViewModel>(context);
    final schedule = commuterVM.selectedSchedule;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          /// Shows route if schedule is loaded, otherwise shows loading
          schedule != null ? "${schedule.pickup} - ${schedule.destination}" : "Loading...",
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            if (schedule != null)
              Text(
                "${schedule.date} | ${schedule.time}",
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            const SizedBox(height: 20),
            const Text("Choose Your Seat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) => seatIcon((index + 1).toString())),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5,
                    itemBuilder: (context, rowIndex) {
                      int base = 5 + (rowIndex * 4) + 1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            seatIcon((base).toString()),
                            seatIcon((base + 1).toString()),
                            const SizedBox(width: 30),
                            seatIcon((base + 2).toString()),
                            seatIcon((base + 3).toString()),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a seat icon widget with seat number
  /// Handles tap to navigate to confirmation screen
  /// Colors the seat red if already booked
  Widget seatIcon(String seatNumber) {
    final commuterVM = Provider.of<CommuterViewModel>(context);
    final isBooked = commuterVM.bookedSeats.contains(seatNumber);

    return Column(
      children: [
        GestureDetector(
          /// Disables tap if seat is already booked
          onTap: isBooked
              ? null
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConfirmDetailScreen(
                  scheduleId: widget.scheduleId,
                  seatNumber: seatNumber,
                ),
              ),
            ).then((value) {
              if (value == true) {
                setState(() {});
              }
            });
          },
          child: Icon(
            Icons.event_seat,
            size: 25,
            color: isBooked ? Colors.red : Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          seatNumber,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isBooked ? Colors.red : Colors.black,
          ),
        ),
      ],
    );
  }
}

/// Screen for confirming booking details
class ConfirmDetailScreen extends StatefulWidget {
  final int scheduleId;
  final String seatNumber;

  const ConfirmDetailScreen({required this.scheduleId, required this.seatNumber, super.key});

  @override
  State<ConfirmDetailScreen> createState() => _ConfirmDetailScreen();
}

class _ConfirmDetailScreen extends State<ConfirmDetailScreen> {
  bool isConfirm = false;

  /// Handles booking confirmation
  void confirmBooking() async {
    final commuterId = Supabase.instance.client.auth.currentUser?.id;
    if (commuterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Not signed in")));
      return;
    }

    final commuterVM = Provider.of<CommuterViewModel>(context, listen: false);
    final error = await commuterVM.confirmBooking(widget.scheduleId, int.parse(widget.seatNumber), commuterId);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      setState(() => isConfirm = true);
    }
  }

  /// Exits the screen after confirmation
  void exitScreen() => Navigator.pop(context, true);

  @override
  Widget build(BuildContext context) {
    final commuterVM = Provider.of<CommuterViewModel>(context);
    final schedule = commuterVM.selectedSchedule;

    return GestureDetector(
      /// Allows tapping anywhere to exit after confirmation
      onTap: isConfirm ? exitScreen : null,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Booking Detail", style: TextStyle(color: isConfirm ? Colors.black38 : Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            /// Dims the form when confirmed
            Opacity(
              opacity: isConfirm ? 0.3 : 1,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Booking Confirmation", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isConfirm ? Colors.black26 : Colors.black)),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: schedule == null
                          ? Text("Loading schedule...")
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(schedule.date, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Pickup", style: TextStyle(fontSize: 14, color: Colors.black54)),
                                  Text(schedule.pickup, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("Departure", style: TextStyle(fontSize: 14, color: Colors.black54)),
                                  Text(schedule.time, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                  Text(schedule.destination, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("Arrival", style: TextStyle(fontSize: 14, color: Colors.black54)),
                                  Text("~TBD", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                              Text(widget.seatNumber, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 40),
                          ElevatedButton(
                            /// Disables button after confirmation
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
            /// Shows confirmation overlay when booking is confirmed
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