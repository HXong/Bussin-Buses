import 'package:flutter/material.dart';

class BookingNav extends StatefulWidget {
  const BookingNav({super.key});

  @override
  State<BookingNav> createState() => _BookingNavState();
}

class _BookingNavState extends State<BookingNav> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Text("Booking Page Testing")
        ],
      ),
    );
  }
}
