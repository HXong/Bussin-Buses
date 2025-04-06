// lib/pages/CommuterNav/ticket_nav.dart
import 'package:bussin_buses/pages/CommuterNav/upcoming_booking.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/commuter_viewmodel.dart';

class TicketNav extends StatefulWidget {
  final Function(int)? onBookingSelected;
  
  const TicketNav({this.onBookingSelected, Key? key}) : super(key: key);

  @override
  TicketNavState createState() => TicketNavState();
}

class TicketNavState extends State<TicketNav> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final viewModel = Provider.of<CommuterViewModel>(context, listen: false);
    await viewModel.obtainId();
    
    // Ensure ETAs are loaded for all bookings
    for (var booking in viewModel.bookings) {
      final scheduleId = viewModel.getScheduleIdFromBooking(booking);
      if (scheduleId > 0) {
        viewModel.fetchETA(scheduleId);
      }
    }
  }

  void fetchBookings() {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final commuterVM = Provider.of<CommuterViewModel>(context);
    final bookings = commuterVM.bookings;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Upcoming Bookings", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Add refresh button
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              fetchBookings();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Refreshing bookings and ETAs...'))
              );
            },
          ),
        ],
      ),
      body: commuterVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookings.isEmpty
          ? const Center(child: Text("No bookings available"))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return BookingCard(
              booking: bookings[index],
              onViewLiveLocation: widget.onBookingSelected,
            );
          },
        ),
      ),
    );
  }
}