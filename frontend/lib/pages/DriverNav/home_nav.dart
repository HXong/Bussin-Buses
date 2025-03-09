import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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
    _fetchUpcomingTrips();
  }

  // Fetch upcoming trips for the current driver from Supabase
  Future<void> _fetchUpcomingTrips() async {
    final driverId = Supabase.instance.client.auth.currentUser?.id;

    if (driverId == null) {
      debugPrint('No user is logged in.');
      return;
    }

    final response = await Supabase.instance.client
        .from('schedules')
        .select()
        .eq('driver_id', driverId)
        .order('date', ascending: true);

    List<Map<String, dynamic>> tripsWithLocations = [];

    for (var trip in response) {
      debugPrint("Fetched trip: $trip");

      // Fetch pickup and destination names
      String pickupName = await _getLocationName(trip['pickup']);
      String destinationName = await _getLocationName(trip['destination']);

      // Parse date & time correctly
      String dateStr = trip['date']; // YYYY-MM-DD
      String timeStr = trip['time']; // HH:MM:SS

      // Format time to only show hours and minutes (hh:mm)
      String startTimeFormatted = timeStr.substring(0, 5);

      // Format date to show as day month (e.g., 20 JAN)
      String formattedDate = _formatDate(dateStr);

      // Add 1 hour and 15 minutes to calculate end time
      DateTime startTime = DateTime.parse('$dateStr $timeStr');
      DateTime endTime = startTime.add(const Duration(minutes: 75));
      String endTimeFormatted = endTime.toIso8601String().substring(11, 16);

      tripsWithLocations.add({
        'schedule_id': trip['schedule_id'], // int
        'date': formattedDate, // formatted date
        'start_time': startTimeFormatted,
        'end_time': endTimeFormatted,
        'duration': '1h 15min',
        'pickup': pickupName,
        'destination': destinationName,
      });
    }

    if (mounted) {
      setState(() {
        upcomingTrips = tripsWithLocations;
      });
    }
  }

  // Fetch location name from location_id
  Future<String> _getLocationName(int locationId) async {
    final response = await Supabase.instance.client
        .from('location')
        .select('location_name')
        .eq('location_id', locationId)
        .single();

    return response?['location_name'] ?? 'Unknown Location';
  }

  // Format date to "day month" (e.g., "20 JAN")
  String _formatDate(String dateStr) {
    DateTime date = DateTime.parse(dateStr); // Convert to DateTime
    return DateFormat('dd MMM')
        .format(date)
        .toUpperCase(); // Format to "20 JAN"
  }

  // Delete a trip from Supabase
  Future<void> _deleteTrip(Map<String, dynamic> trip) async {
    await Supabase.instance.client
        .from('schedules')
        .delete()
        .eq('schedule_id', trip['schedule_id']); // int

    if (mounted) {
      setState(() {
        upcomingTrips.remove(trip);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Trips',
          style: TextStyle(fontSize: 25,
              fontWeight: FontWeight.bold))),
      body: SafeArea(
        child: upcomingTrips.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: upcomingTrips.length,
          itemBuilder: (context, index) {
            final trip = upcomingTrips[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 5,
              color: Colors.grey.shade300,
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Formatted Date
                    Text(trip['date'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // Time Range and Duration
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(trip['start_time'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Text('-----', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
                          ),
                        ),
                        Text(trip['duration'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Text('-----', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
                          ),
                        ),
                        Text(trip['end_time'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Pickup & Destination
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(trip['pickup'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        Text(trip['destination'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.chevron_right, size:30),
                  onPressed: () {
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
                style: const TextStyle(fontSize: 20),
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
