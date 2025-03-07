import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduleNav extends StatefulWidget {
  const ScheduleNav({super.key});

  @override
  State<ScheduleNav> createState() => _ScheduleNavState();
}

class _ScheduleNavState extends State<ScheduleNav> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  List<String> _locations = []; // List to hold location names
  String? _selectedPickup; // Variable to hold the selected pickup point
  String? _selectedDestination; // Variable to hold the selected destination

  @override
  void initState() {
    super.initState();
    _fetchLocations(); // Fetch locations when the widget is initialized
  }

  // Function to fetch locations from Supabase
  Future<void> _fetchLocations() async {
    try {
      final response = await Supabase.instance.client
          .from('location')
          .select('location_name');

      setState(() {
        _locations = response.map<String>((row) => row['location_name'] as String).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching locations: $e")),
      );
    }
  }

  Future<int?> _getLocationIdByName(String locationName) async {
    try {
      final response = await Supabase.instance.client
          .from('location')
          .select('location_id')
          .eq('location_name', locationName)
          .single();

      if (response != null) {
        return response['location_id'];
      }
      return null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location ID: $e')),
      );
      return null; // Return null if an error occurs
    }
  }

// submitForm function to store the response
  Future<void> _submitForm() async {
    final pickupPoint = _selectedPickup;
    final destination = _selectedDestination;
    final date = _dateController.text;
    final time = _timeController.text;

    // Check if any of the fields are empty or null
    if (pickupPoint == null || destination == null || date.isEmpty || time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    // Validate date format (yyyy-MM-dd)
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid date format. Use yyyy-MM-dd.")),
      );
      return;
    }

    // Validate time format (HH:mm)
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(time)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid time format. Use HH:mm.")),
      );
      return;
    }

    // Fetch the IDs for the selected pickup and destination
    final pickupId = await _getLocationIdByName(pickupPoint);
    final destinationId = await _getLocationIdByName(destination);

    // Check if the IDs are found
    if (pickupId == null || destinationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching location IDs.")),
      );
      return;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not authenticated. Please log in.")),
        );
        return;
      }

      final response = await Supabase.instance.client.from('schedules').insert({
        'pickup': pickupId, // Store the location ID for pickup
        'destination': destinationId, // Store the location ID for destination
        'date': date,
        'time': time,
        'driver_id': userId,
      }).select();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Journey added successfully!")),
      );

      // Clear all fields after successful submission
      _dateController.clear();
      _timeController.clear();
      setState(() {
        _selectedPickup = null;
        _selectedDestination = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding journey: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.directions_bus_filled, size: 100),
              const SizedBox(height: 20),
              const Text(
                "Add Journey",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),

              // Pick-Up Point Dropdown with Downward Arrow
              _locations.isEmpty
                  ? const CircularProgressIndicator()
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedPickup,
                  items: _locations.map((location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPickup = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Pick-Up Point",
                    filled: true,
                    fillColor: Colors.grey[400],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Destination Dropdown with Downward Arrow
              _locations.isEmpty
                  ? const CircularProgressIndicator()
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedDestination,
                  items: _locations.map((location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDestination = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Destination",
                    filled: true,
                    fillColor: Colors.grey[400],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Date Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: "Date",
                    filled: true,
                    fillColor: Colors.grey[400],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Time Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    labelText: "Time",
                    filled: true,
                    fillColor: Colors.grey[400],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text("Add Journey"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}