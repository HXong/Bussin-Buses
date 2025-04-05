import 'package:bussin_buses/viewmodels/trip_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'trip_list_ui.dart';

class UpcomingTrips extends StatelessWidget {
  const UpcomingTrips({super.key});

  @override
  Widget build(BuildContext context) {
    final tripViewModel = Provider.of<TripViewModel>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('All Upcoming Trips')),
      body: SafeArea(
        child: tripViewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TripList(trips: tripViewModel.upcomingAllTrips, noTripsMessage: 'No upcoming trips available.'),
      )
    );
  }
}
