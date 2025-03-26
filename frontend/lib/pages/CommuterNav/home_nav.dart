import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeNav extends StatefulWidget {
  final void Function(int)? onScheduleSelected;
  const HomeNav({this.onScheduleSelected, super.key});

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> schedules = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSchedules();
  }

  Future<void> fetchSchedules() async {
    try {
      final response = await supabase
          .from('schedules')
          .select('schedule_id, date, time, pickup(location_name), destination(location_name)');

      setState(() {
        schedules = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching schedules: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Available Schedules"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : schedules.isEmpty
          ? Center(child: Text("No schedules available"))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          final schedule = schedules[index];
          final scheduleId = schedule['schedule_id'];

          final date = schedule['date'] != null
              ? DateTime.parse(schedule['date'])
              : DateTime.now();
          final dateFormatted =
              '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}';

          final time = schedule['time'] ?? '--:--';
          final pickup = schedule['pickup']?['location_name'] ?? 'N/A';
          final destination = schedule['destination']?['location_name'] ?? 'N/A';

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            margin: EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text('$pickup → $destination'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: $dateFormatted'),
                  Text('Time: $time'),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  widget.onScheduleSelected?.call(scheduleId);
                },
                child: Text("Select"),
              ),
            ),
          );
        },
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}