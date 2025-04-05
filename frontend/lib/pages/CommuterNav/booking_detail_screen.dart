import 'package:bussin_buses/models/Booking.dart';
import 'package:bussin_buses/viewmodels/commuter_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BookingDetailScreen extends StatelessWidget {
  final Booking booking;
  const BookingDetailScreen({required this.booking});

  @override
  Widget build(BuildContext context) {
    final commuterVM = Provider.of<CommuterViewModel>(context);
    final details = booking.displayDetails;

    return Scaffold(
      appBar: AppBar(
        title: Text("Booking Detail", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Booking Detail", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(details['scheduleDate']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Pickup", style: TextStyle(fontSize: 14, color: Colors.black54)),
                          Text(details['pickup']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Departure", style: TextStyle(fontSize: 14, color: Colors.black54)),
                          Text(details['departureTime']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                          Text(details['destination']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Arrival", style: TextStyle(fontSize: 14, color: Colors.black54)),
                          Text(details['arrivalTime']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 20),
                      const SizedBox(width: 4),
                      const Text("1", style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 10),
                      const Icon(Icons.event_seat, size: 20),
                      const SizedBox(width: 4),
                      Text(details['seatNumber']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: commuterVM.isCheckIn(booking.id)
                        ? null
                        : () async {
                      final error = await commuterVM.checkIn(booking);
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Check-In successful.")));
                        Navigator.pop(context, true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: const Text("Check In", style: TextStyle(color: Colors.black)),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: commuterVM.isCanceled(booking.id)
                        ? null
                        : () async {
                      final isEligible = await commuterVM.handleCancelWithTimeCheck(booking);
                      if (!isEligible) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Cancellation must be done at least 30 minutes before departure.")),
                        );
                        return;
                      }
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Cancel Booking'),
                            content: const Text('Are you sure you want to cancel this booking?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
                              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes, Cancel')),
                            ],
                          );
                        },
                      );
                      if (confirm != true) return;

                      final error = await commuterVM.cancelBooking(booking);
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Booking canceled successfully!")));
                        Navigator.pop(context, true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: const Text("Cancel Booking", style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
