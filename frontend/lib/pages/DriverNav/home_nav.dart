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

  // Simulate dynamic data fetching for the driver
  List<Map<String, String>> upcomingTrips = [];

  @override
  void initState() {
    super.initState();
    _fetchUpcomingTrips();
  }

  // Simulating fetching trips for the driver
  void _fetchUpcomingTrips() {
    // Replace with actual fetching logic
    // Simulating dynamic trips for this example
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        upcomingTrips = [
          {
            'date': 'JAN 20, 2025',
            'start_time': '17:00',
            'end_time': '18:15',
            'duration': '1h 15mins',
            'pickup': 'NTU',
            'destination': 'Tampines',
          },
          {
            'date': 'JAN 21, 2025',
            'start_time': '08:30',
            'end_time': '09:45',
            'duration': '1h 15mins',
            'pickup': 'NTU',
            'destination': 'Downtown MRT',
          },
          {
            'date': 'JAN 22, 2025',
            'start_time': '10:00',
            'end_time': '11:15',
            'duration': '1h 15mins',
            'pickup': 'NTU',
            'destination': 'Jurong East',
          },
        ];
      });
    });
  }

  void _deleteTrip(Map<String, String> trip) {
    setState(() {
      upcomingTrips.remove(trip);
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
      appBar: AppBar(
        title: const Text('Upcoming Trips'),
        backgroundColor: Colors.grey,
      ),
      body: SafeArea(
        child: upcomingTrips.isEmpty
            ? const Center(
          child: CircularProgressIndicator(), // Loading indicator
        )
            : ListView.builder(
          itemCount: upcomingTrips.length,
          itemBuilder: (context, index) {
            final trip = upcomingTrips[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              color: Colors.grey.shade300,
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          trip['date']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Time Range and Duration with Separators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Start Time
                        Text(
                          trip['start_time']!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // First Separator
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Text(
                              '-----',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        // Duration
                        Text(
                          trip['duration']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            //color: Colors.grey,
                          ),
                        ),
                        // Second Separator
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Text(
                              '-----',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        // End Time
                        Text(
                          trip['end_time']!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Pick-Up and Destination
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          trip['pickup']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          trip['destination']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    // Navigate to the trip details screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TripDetailsScreen(
                          trip: trip,
                          onDelete: _deleteTrip,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class TripDetailsScreen extends StatelessWidget {
  final Map<String, String> trip;
  final Function(Map<String, String>) onDelete;

  const TripDetailsScreen({Key? key, required this.trip, required this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${trip['pickup']} - ${trip['destination']} ',
                  style: const TextStyle(fontSize: 35,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${trip['date']} | ',
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  '${trip['start_time']}',
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Passenger Details ',
                  style: const TextStyle(fontSize: 25,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                _showDeleteConfirmationDialog(context);
              },
              child: const Text('Delete Trip'),
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
