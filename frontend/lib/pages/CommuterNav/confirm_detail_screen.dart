import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../viewmodels/commuter_viewmodel.dart';

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
  /// Checks if user is signed in and calls view model to create booking
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

  /// Exits screen and refreshes bookings list
  void exitScreen() async {
    // Get the commuter view model to refresh the bookings list
    final commuterVM = Provider.of<CommuterViewModel>(context, listen: false);
    final commuterId = Supabase.instance.client.auth.currentUser?.id;
    if (commuterId != null) {
      // Wait for the bookings to be fetched before navigating
      await commuterVM.fetchBookings(commuterId);
    }
    
    // Pop twice to go back to the home screen
    Navigator.pop(context, true);
    Navigator.pop(context, true);
  }

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