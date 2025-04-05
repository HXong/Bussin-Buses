import 'package:bussin_buses/pages/CommuterNav/upcoming_booking.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/commuter_viewmodel.dart';

class TicketNav extends StatefulWidget {
  const TicketNav({Key? key}) : super(key: key);

  @override
  TicketNavState createState() => TicketNavState();
}

class TicketNavState extends State<TicketNav> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CommuterViewModel>(context, listen: false).obtainId();
    });
  }


  void fetchBookings() {
    Provider.of<CommuterViewModel>(context, listen: false).obtainId();
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
            return BookingCard(booking: bookings[index]);
          },
        ),
      ),
    );
  }
}
