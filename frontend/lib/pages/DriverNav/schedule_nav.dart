import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';  // Import Supabase package

class ScheduleNav extends StatefulWidget {
  const ScheduleNav({super.key});

  @override
  State<ScheduleNav> createState() => _ScheduleNavState();
}

class _ScheduleNavState extends State<ScheduleNav> {
  final TextEditingController _pickupPointController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  // Function to handle form submission
  Future<void> _submitForm() async {
    final pickupPoint = _pickupPointController.text;
    final destination = _destinationController.text;
    final date = _dateController.text;
    final time = _timeController.text;

    if (pickupPoint.isEmpty || destination.isEmpty || date.isEmpty || time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    // Date validation: Check if the date is in the correct format (YYYY-MM-DD)
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid date format. Please use YYYY-MM-DD.")),
      );
      return;
    }

    // Date range validation: Check if the entered date is not in the past
    final enteredDate = DateTime.tryParse(date);
    final today = DateTime.now();
    if (enteredDate == null || enteredDate.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Date must be today or later.")),
      );
      return;
    }

    // Time validation: Check if the time is in the correct format (HH:MM)
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(time)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid time format. Please use HH:MM.")),
      );
      return;
    }

    try {
      // Get the current authenticated user ID
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not authenticated. Please log in.")),
        );
        return;
      }

      // Insert the schedule into the Supabase database with the user ID
      final response = await Supabase.instance.client.from('schedules').insert({
        'pickup': pickupPoint,
        'destination': destination,
        'date': date,
        'time': time,
        'id': userId,
      }).select();

      // Show a success message after successfully adding the schedule
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Journey added successfully!")),
      );

      // Clear the text fields after submission
      _pickupPointController.clear();
      _destinationController.clear();
      _dateController.clear();
      _timeController.clear();
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: _pickupPointController,
                  decoration: InputDecoration(
                    labelText: "Pick-Up Point",
                    filled: true,
                    fillColor: Colors.grey[400],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: "Destination",
                    filled: true,
                    fillColor: Colors.grey[400],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: "Date (YYYY-MM-DD)",
                    filled: true,
                    fillColor: Colors.grey[400],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    labelText: "Time (HH:MM)",
                    filled: true,
                    fillColor: Colors.grey[400],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "Add Journey",
                    style: TextStyle(fontSize: 18, color: Colors.white),
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
