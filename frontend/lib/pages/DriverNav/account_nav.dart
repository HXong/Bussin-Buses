import 'package:flutter/material.dart';
import 'personal_information.dart';
import 'past_trips.dart';
import 'upcoming_trips.dart';
import 'feedback.dart';

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
            _buildButton(context, "Personal Information", const PersonalInformation()),
            const SizedBox(height: 30),
            _buildButton(context, "Past Trips", const PastTrips()),
            const SizedBox(height: 30),
            _buildButton(context, "All Upcoming Trips", const UpcomingTrips()),
            const SizedBox(height: 30),
            _buildButton(context, "Feedback", const FeedbackScreen()),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, Widget? page, {String? route}) {
    return SizedBox(
      width: 300,
      child: ElevatedButton(
        onPressed: () {
          if (route != null) {
            Navigator.pushNamed(context, route);
          } else if (page != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => page));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 20)),
      ),
    );
  }
}
