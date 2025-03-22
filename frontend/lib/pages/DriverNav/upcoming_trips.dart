import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/driver_viewmodel.dart';
import 'trip_list_ui.dart';

class UpcomingTrips extends StatelessWidget {
  const UpcomingTrips({super.key});

  @override
  Widget build(BuildContext context) {
    final driverViewModel = Provider.of<DriverViewModel>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('All Upcoming Trips')),
      body: SafeArea(
        child: driverViewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TripList(trips: driverViewModel.upcomingAllTrips, noTripsMessage: 'No upcoming trips available.'),
      ),
    );
  }
}
