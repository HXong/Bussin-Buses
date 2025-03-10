import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'trip_function.dart';
import 'trip_list_UI.dart';

class AccountNav extends StatefulWidget {
  const AccountNav({super.key});

  @override
  State<AccountNav> createState() => _AccountNavState();
}

class _AccountNavState extends State<AccountNav> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 90),
            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PersonalInformation(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  "Personal Information",
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/forget');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  "Change Password",
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PastTrips(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  "Past Trips",
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UpcomingTrips(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  "Upcoming Trips",
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Feedback(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  "Feedback",
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
              ),
            ),
            const SizedBox(height: 90),

            // SizedBox(
            //   width: 300,
            //   child: ElevatedButton(
            //     onPressed: () {
            //       Navigator.pushNamed(context, '/login');
            //     },
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.grey[300],
            //       padding: const EdgeInsets.symmetric(vertical: 15),
            //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            //     ),
            //     child: const Text(
            //       "Log Out",
            //       style: TextStyle(color: Colors.black, fontSize: 20),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class PersonalInformation extends StatefulWidget {
  const PersonalInformation({super.key});

  @override
  _PersonalInformationState createState() => _PersonalInformationState();
}

class _PersonalInformationState extends State<PersonalInformation> {
  String name = "Driver Name";
  String role = "Driver";
  String vehiclePlate = "Unknown";
  String date = "Unknown";
  String profilePicUrl = 'https://creazilla-store.fra1.digitaloceanspaces.com/cliparts/7937373/bus-driver-clipart-md.png';

  @override
  void initState() {
    super.initState();
    fetchPersonalInformation();
  }

  Future<void> fetchPersonalInformation() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('username, user_type, created_at')
          .eq('id', userId)
          .single();

      final busResponse = await Supabase.instance.client
          .from('buses')
          .select('bus_number')
          .eq('driver_id', userId)
          .single();

      if (mounted) {
        setState(() {
          name = response['username'] ?? name;
          role = response['role'] ?? role;
          vehiclePlate = busResponse['bus_number'] ?? vehiclePlate;
          DateTime dateTime = DateTime.parse(response['created_at']);
          date = DateFormat('dd MMM yyyy').format(dateTime);
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Information')),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 70),
            CircleAvatar(
              radius: 120,
              backgroundImage: NetworkImage(profilePicUrl),
            ),
            const SizedBox(height: 40),

            Text(name,
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),

            Text("Role: $role",
                style: const TextStyle(fontSize: 23)),
            const SizedBox(height: 30),

            Text("Bus Plate: $vehiclePlate",
                style: const TextStyle(fontSize: 23)),
            const SizedBox(height: 30),

            Text("Date Joined: $date",
                style: const TextStyle(fontSize: 23)),
          ],
        ),
      ),
    );
  }
}

class PastTrips extends StatefulWidget {
  const PastTrips({super.key});

  @override
  _PastTripsState createState() => _PastTripsState();
}

class _PastTripsState extends State<PastTrips> {
  List<Map<String, dynamic>> pastTrips = [];

  @override
  void initState() {
    super.initState();
    _fetchPastTrips(DateTime.now());
  }

  // Fetch past trips for the current driver from Supabase
  Future<void> _fetchPastTrips(DateTime targetDate) async {
    final driverId = Supabase.instance.client.auth.currentUser?.id;

    if (driverId == null) {
      debugPrint('No user is logged in.');
      return;
    }

    // Use the imported function to fetch past trips
    List<Map<String, dynamic>> tripsWithLocations = await fetchTrips(driverId, targetDate, true);

    if (mounted) {
      setState(() {
        pastTrips = tripsWithLocations;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Past Trips',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: TripList(
          trips: pastTrips,
          noTripsMessage: 'No past trips available.',
        ),
      ),
    );
  }
}

class UpcomingTrips extends StatefulWidget {
  const UpcomingTrips({super.key});

  @override
  _UpcomingTripsState createState() => _UpcomingTripsState();
}

class _UpcomingTripsState extends State<UpcomingTrips> {
  List<Map<String, dynamic>> upcomingTrips = [];

  @override
  void initState() {
    super.initState();
    _fetchUpcomingTrips(DateTime.now());
  }

  // Fetch past trips for the current driver from Supabase
  Future<void> _fetchUpcomingTrips(DateTime targetDate) async {
    final driverId = Supabase.instance.client.auth.currentUser?.id;

    if (driverId == null) {
      debugPrint('No user is logged in.');
      return;
    }

    // Use the imported function to fetch past trips
    List<Map<String, dynamic>> tripsWithLocations = await fetchTrips(driverId, targetDate, false);

    if (mounted) {
      setState(() {
        upcomingTrips = tripsWithLocations;
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
        ),
      ),
    );
  }
}

class Feedback extends StatefulWidget {
  const Feedback({super.key});

  @override
  _FeedbackState createState() => _FeedbackState();
}

class _FeedbackState extends State<Feedback> {
  final TextEditingController _feedbackController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _getFeedback();
  }

  final userId = Supabase.instance.client.auth.currentUser?.id;

  Future<void> _getFeedback() async {
    final feedback = _feedbackController.text;
    if (feedback.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")));
      return;
    }

    await Supabase.instance.client.from('feedback').insert({
      'feedback': feedback,
      'user_id':userId,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Feedback submitted successfully!")),
    );

    _feedbackController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 50),
              const Icon(Icons.directions_bus_filled, size: 150),
              const SizedBox(height: 10),
              const Text(
                "Feedback",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: TextField(
                     controller: _feedbackController,
                      decoration: InputDecoration(
                        labelText: "Feedback",
                        filled: true,
                        fillColor: Colors.grey[400],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                ),
                const SizedBox(height: 170),
                ElevatedButton(
                onPressed: _getFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF000066),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                  child: const Text("Submit Feedback", style: TextStyle(color: Colors.white,)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


