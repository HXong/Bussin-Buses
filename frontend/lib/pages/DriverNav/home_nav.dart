import 'package:bussin_buses/pages/DriverNav/trip_detail_screen.dart';
import 'package:bussin_buses/viewmodels/driver_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'trip_list_UI.dart';

class HomeNav extends StatefulWidget {
  const HomeNav({super.key});

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  @override
  Widget build(BuildContext context) {
    final driverViewModel = Provider.of<DriverViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upcoming Trips',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: driverViewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TripList(
          trips: driverViewModel.upcomingConfirmedTrips,
          noTripsMessage: 'No upcoming trips available.',
          onTap: (trip) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TripDetailsScreen(trip: trip),
              ),
            );
          },
        ),
      ),
    );
  }
}

