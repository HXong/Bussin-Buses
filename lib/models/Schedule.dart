import 'package:intl/intl.dart';

class Schedule {
  final String pickup;
  final String destination;
  final String date;
  final String time;

  Schedule({
    required this.pickup,
    required this.destination,
    required this.date,
    required this.time,
  });

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      pickup: map['pickup']?['location_name'] ?? 'N/A',
      destination: map['destination']?['location_name'] ?? 'N/A',
      date: map['date'] ?? '',
      time: map['time']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pickup': pickup,
      'destination': destination,
      'date': date,
      'time': time,
    };
  }

  String get formattedDate {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('EEE, dd MMM yyyy').format(parsed);
    } catch (_) {
      return 'Unknown Date';
    }
  }

  String get formattedTime {
    try {
      final parts = time.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final parsed = DateTime(2025, 1, 1, hour, minute);
      return DateFormat('HH:mm').format(parsed);
    } catch (_) {
      return 'Unknown Time';
    }
  }

}
