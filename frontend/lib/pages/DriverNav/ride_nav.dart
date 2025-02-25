import 'package:flutter/material.dart';

class RideNav extends StatefulWidget {
  const RideNav({super.key});

  @override
  State<RideNav> createState() => _RideNavState();
}

class _RideNavState extends State<RideNav> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Text("Ride Testing")
        ],
      ),
    );
  }
}
