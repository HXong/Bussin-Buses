import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/driver_viewmodel.dart';
import 'trip_list_ui.dart';

class PastTrips extends StatefulWidget {
  const PastTrips({super.key});

  @override
  State<PastTrips> createState() => _PastTripsState();
}

class _PastTripsState extends State<PastTrips> {
  @override
  Widget build(BuildContext context) {
    final driverViewModel = Provider.of<DriverViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Past Trips')),
      body: SafeArea(
        child: driverViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TripList(
            trips: driverViewModel.pastTrips, noTripsMessage: 'No past trips.'),
      ),
    );
  }
}
