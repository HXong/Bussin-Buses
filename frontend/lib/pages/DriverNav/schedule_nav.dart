import 'package:flutter/material.dart';

class ScheduleNav extends StatefulWidget {
  const ScheduleNav({super.key});

  @override
  State<ScheduleNav> createState() => _ScheduleNavState();
}

class _ScheduleNavState extends State<ScheduleNav> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Text("Schedule Testing")
        ],
      ),
    );
  }
}
