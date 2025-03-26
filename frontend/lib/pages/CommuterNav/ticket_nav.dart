import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'upcoming_booking.dart';

class TicketNav extends StatefulWidget {
  const TicketNav({Key? key}) : super(key: key);

  @override
  TicketNavState createState() => TicketNavState();
}

class TicketNavState extends State<TicketNav> {
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
      print("Refetching bookings...");
      final response = await supabase
          .from('bookings')
          .select('booking_id, booking_date, is_checked_in, seat_id(seat_number), schedule_id(date, time, pickup(location_name), destination(location_name))');

      final List<Map<String, dynamic>> allBookings = List<Map<String, dynamic>>.from(response);
      final List<Map<String, dynamic>> upcomingBookings = [];

      for (var booking in allBookings) {
        final scheduleDateRaw = booking['schedule_id']?['date'];
        final scheduleTimeRaw = booking['schedule_id']?['time']?.toString();

        if (scheduleDateRaw != null && scheduleTimeRaw != null && scheduleTimeRaw.contains(':')) {
          try {
            final date = DateTime.parse(scheduleDateRaw);
            final timeParts = scheduleTimeRaw.split(':');
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);

            final departureDateTime = DateTime(
              date.year,
              date.month,
              date.day,
              hour,
              minute,
            );

            if (departureDateTime.isAfter(DateTime.now())) {
              upcomingBookings.add(booking);
            }
          } catch (e) {
            print("Error parsing booking time: $e");
          }
        }
      }

      setState(() {
        bookings = upcomingBookings;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching bookings: $e');
      setState(() => isLoading = false);
    }
  }


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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : bookings.isEmpty
          ? Center(child: Text("No bookings available"))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return BookingCard(booking: booking);
          },
        ),
      ),
    );
  }
}


