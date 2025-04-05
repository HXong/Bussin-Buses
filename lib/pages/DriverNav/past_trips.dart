import 'package:bussin_buses/viewmodels/trip_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'trip_list_ui.dart';

class PastTrips extends StatefulWidget {
  const PastTrips({super.key});

  @override
  State<PastTrips> createState() => _PastTripsState();
}

class _PastTripsState extends State<PastTrips> {
  @override
  Widget build(BuildContext context) {
    final tripViewModel = Provider.of<TripViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Past Trips')),
      body: SafeArea(
        child: tripViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TripList(
            trips: tripViewModel.pastTrips, noTripsMessage: 'No past trips.'),
      ),
    );
  }
}
