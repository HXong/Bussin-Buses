import 'package:bussin_buses/pages/DriverNav/passenger_details_UI.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bussin_buses/models/Trips.dart';
import '../../viewmodels/driver_viewmodel.dart';

class TripDetailsScreen extends StatefulWidget {
  final Trip trip;
  const TripDetailsScreen({super.key, required this.trip});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driverViewModel = Provider.of<DriverViewModel>(context, listen: false);
      final scheduleId = widget.trip.scheduleId.toString(); // Accessing scheduleId from the Trip model
      driverViewModel.fetchPassengerDetails(scheduleId); // Fetch passengers for the trip
    });
  }

  @override
  Widget build(BuildContext context) {
    final driverViewModel = Provider.of<DriverViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      '${widget.trip.pickup} - ${widget.trip.destination}',
                      style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Center(
                    child: Text(
                      '${widget.trip.date} | ${widget.trip.startTime}', // Use the properties of Trip model
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 40),

                  const Center(
                    child: Text(
                      'Passenger Manifest',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),

                  driverViewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : PassengerList(
                    passengers: driverViewModel.passengers, // Displaying passengers
                    noPassengerMessage: 'No passengers found.',
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(50),
            child: SizedBox(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000066),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  _showDeleteConfirmationDialog(context, driverViewModel);
                },
                child: const Text(
                  'Delete Trip',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, DriverViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Trip'),
          content: const Text('Are you sure you want to delete this trip?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                await viewModel.deleteTrip(widget.trip); // Pass the Trip object for deletion

                if (mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Trip deleted successfully!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
