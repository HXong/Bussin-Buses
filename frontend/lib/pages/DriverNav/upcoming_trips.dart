import 'package:bussin_buses/viewmodels/trip_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'trip_list_ui.dart';

class UpcomingTrips extends StatefulWidget {
  const UpcomingTrips({super.key});

  @override
  State<UpcomingTrips> createState() => _UpcomingTripsState();
}

class _UpcomingTripsState extends State<UpcomingTrips> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      Provider.of<TripViewModel>(context, listen: false)
          .fetchAllUpcomingTrips(DateTime.now().toUtc().add(const Duration(hours: 8)));
      _isInitialized = true;
    }
  }
  @override
  Widget build(BuildContext context) {
    final tripViewModel = Provider.of<TripViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('All Upcoming Trips')),
      body: SafeArea(
        child: !tripViewModel.hasFetchedAllTrips
            ? const Center(child: CircularProgressIndicator())
            : (tripViewModel.upcomingAllTrips.isEmpty
            ? const Center(child: Text('No upcoming trips available.'))
            : TripList(
          trips: tripViewModel.upcomingAllTrips,
          noTripsMessage: 'No upcoming trips available.',
        )),
      ),
    );
  }

}
