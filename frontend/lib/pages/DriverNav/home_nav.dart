import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'trip_function.dart';
import 'trip_list_UI.dart';

class HomeNav extends StatefulWidget {
  const HomeNav({super.key});

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  List<Map<String, dynamic>> upcomingTrips = [];

  @override
  void initState() {
    super.initState();
    _fetchUpcomingTrips(DateTime.now());
  }

  // Fetch upcoming trips for the current driver from Supabase
  Future<void> _fetchUpcomingTrips(DateTime targetDate) async {
    final driverId = Supabase.instance.client.auth.currentUser?.id;

    if (driverId == null) {
      debugPrint('No user is logged in.');
      return;
    }

    List<Map<String, dynamic>> tripsWithLocations = await fetchTrips(driverId, targetDate, false);

    if (mounted) {
      setState(() {
        upcomingTrips = tripsWithLocations;
      });
    }
  }

  // Delete a trip from Supabase
  Future<void> _deleteTrip(Map<String, dynamic> trip) async {
    await Supabase.instance.client
        .from('schedules')
        .delete()
        .eq('schedule_id', trip['schedule_id']);

    if (mounted) {
      setState(() {
        upcomingTrips.remove(trip);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upcoming Trips',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: TripList(
          trips: upcomingTrips,
          noTripsMessage: 'No upcoming trips available.',
          onTap: (trip) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TripDetailsScreen(trip: trip, onDelete: _deleteTrip),
              ),
            );
          },
        ),
      ),
    );
  }
}

class TripDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> trip;
  final Function(Map<String, dynamic>) onDelete;

  const TripDetailsScreen({Key? key, required this.trip, required this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '${trip['pickup']} - ${trip['destination']}',
                style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 5),
            Center(
              child: Text(
                '${trip['date']} | ${trip['start_time']}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            // Centering the Passenger Manifest and Button
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Keeps column's size minimal
                  children: [
                    const Text(
                      'Passenger Manifest',
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF000066),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () {
                        _showDeleteConfirmationDialog(context);
                      },
                      child: const Text(
                        'Delete Trip',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
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
                await onDelete(trip);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
