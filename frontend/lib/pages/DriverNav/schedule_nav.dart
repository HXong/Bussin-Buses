import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bussin_buses/viewmodels/driver_viewmodel.dart';

class ScheduleNav extends StatefulWidget {
  const ScheduleNav({super.key});

  @override
  _ScheduleNavState createState() => _ScheduleNavState();
}

class _ScheduleNavState extends State<ScheduleNav> {
  @override
  void initState() {
    super.initState();
    // Call loadLocations when the widget is initialized
    final driverViewModel = Provider.of<DriverViewModel>(context, listen: false);
    driverViewModel.loadLocations();
  }

  @override
  Widget build(BuildContext context) {
    final driverViewModel = Provider.of<DriverViewModel>(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              //const SizedBox(height: 20),
              const Icon(Icons.directions_bus_filled, size: 100),
              const SizedBox(height: 20),
              const Text(
                "Add Journey",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Pick-Up Point Dropdown with Downward Arrow
              driverViewModel.isLoading
                  ? const CircularProgressIndicator()
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: DropdownButtonFormField<String>(
                  value: driverViewModel.selectedPickup,
                  items: driverViewModel.locations.map((location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: driverViewModel.updateSelectedPickup,
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
              driverViewModel.isLoading
                  ? const CircularProgressIndicator()
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: DropdownButtonFormField<String>(
                  value: driverViewModel.selectedDestination,
                  items: driverViewModel.locations.map((location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: driverViewModel.updateSelectedDestination,
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

              // Date Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: driverViewModel.dateController,
                  decoration: InputDecoration(
                    labelText: 'Date (yyyy-mm-dd)',
                    filled: true,
                    fillColor: Colors.grey[400],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: DropdownButtonFormField<String>(
                  value: driverViewModel.pickedTime, // The selected value
                  decoration: InputDecoration(
                    labelText: 'Time',
                    filled: true,
                    fillColor: Colors.grey[400],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  items: List.generate(25, (index) {
                    int hour = 9 + (index ~/ 2);
                    int minute = (index % 2) * 30;
                    String time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                    return DropdownMenuItem(
                      value: time,
                      child: Text(time),
                    );
                  }),
                  onChanged: (String? newValue) {
                    driverViewModel.pickedTime = newValue;
                  },
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: () {
                  driverViewModel.submitJourney(context);
                },
                child: const Text('Submit Journey', style: TextStyle(color: Colors.white,)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF000066),
                  padding: const EdgeInsets.symmetric(
                      vertical: 15.0, horizontal: 50.0),
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
