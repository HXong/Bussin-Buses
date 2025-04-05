import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bussin_buses/viewmodels/driver_viewmodel.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {

  @override
  Widget build(BuildContext context) {
    final driverViewModel = Provider.of<DriverViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Feedback")),
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
                controller: driverViewModel.feedbackController,
                decoration: InputDecoration(
                  labelText: "Feedback",
                  filled: true,
                  fillColor: Colors.grey[400],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),

            const SizedBox(height: 150),
            ElevatedButton(
                onPressed: () {
                  driverViewModel.submitFeedback(context);
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF000066),
                padding: const EdgeInsets.symmetric(
                    vertical: 15.0, horizontal: 50.0),
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
