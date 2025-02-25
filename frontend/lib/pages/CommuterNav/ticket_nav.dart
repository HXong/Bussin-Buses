import 'package:flutter/material.dart';

class TicketNav extends StatefulWidget {
  const TicketNav({super.key});

  @override
  State<TicketNav> createState() => _TicketNavState();
}

class _TicketNavState extends State<TicketNav> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Text("Ticket Page Testing")
        ],
      ),
    );
  }
}
