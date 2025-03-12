import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'trip_function.dart';
import 'trip_list_UI.dart';
import 'passenger_details_function.dart';
import 'passenger_details_UI.dart';

class HomeNav extends StatefulWidget {
  const HomeNav({super.key});

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  List<Map<String, dynamic>> upcomingTrips = [];
  bool tripLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingTrips(DateTime.now());
  }

  Future<void> _fetchUpcomingTrips(DateTime targetDate) async {
    final driverId = Supabase.instance.client.auth.currentUser?.id;

    if (driverId == null) {
      debugPrint('No user is logged in.');
      return;
    }

    List<Map<String, dynamic>> tripsWithLocations = await fetchTrips(driverId, targetDate, false, true);

    if (mounted) {
      setState(() {
        upcomingTrips = tripsWithLocations;
        tripLoading  = false;
      });
    }
  }

  Future<void> _deleteTrip(Map<String, dynamic> trip) async {
    await Supabase.instance.client
        .from('schedules')
        .update({'delete_schedule': true})
        .eq('schedule_id', trip['schedule_id']);

    setState(() {
      upcomingTrips.removeWhere((t) => t['schedule_id'] == trip['schedule_id']);
    });
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
        child: tripLoading
            ? const Center(child: CircularProgressIndicator())
            : TripList(
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

class TripDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> trip;
  final Function(Map<String, dynamic>) onDelete;

  const TripDetailsScreen({Key? key, required this.trip, required this.onDelete}) : super(key: key);

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  List<dynamic> passengers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPassengerDetails();
  }

  Future<void> _fetchPassengerDetails() async {
    final scheduleId = widget.trip['schedule_id'].toString();
    List<Map<String, dynamic>> passengerDetails = await fetchPassengerDetails(scheduleId);

    if (mounted) {
      setState(() {
        passengers = passengerDetails;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      '${widget.trip['pickup']} - ${widget.trip['destination']}',
                      style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Center(
                    child: Text(
                      '${widget.trip['date']} | ${widget.trip['start_time']}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      'Passenger Manifest',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),

                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : PassengerList(
                    passengers: passengers,
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
                  _showDeleteConfirmationDialog(context);
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
                await widget.onDelete(widget.trip);

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
