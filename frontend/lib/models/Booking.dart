import 'package:intl/intl.dart';
import 'Schedule.dart';

/// Booking model is used for Commuter's bus bookings
class Booking {
  final int id;
  final String? seatNumber;
  final Schedule? schedule;
  final bool isCheckedIn;

  Booking({
    required this.id,
    this.seatNumber,
    this.schedule,
    required this.isCheckedIn,
  });

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: int.tryParse(map['booking_id'].toString()) ?? -1,
      seatNumber: map['seat_id']?['seat_number']?.toString(),
      schedule: map['schedule_id'] != null ? Schedule.fromMap(map['schedule_id']) : null,
      isCheckedIn: map['is_checked_in'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'booking_id': id,
    'seat_number': seatNumber,
    'schedule': schedule?.toMap(),
    'is_checked_in': isCheckedIn,
  };

  Map<String, String> get displayDetails {
    return {
      'pickup': schedule?.pickup ?? 'N/A',
      'destination': schedule?.destination ?? 'N/A',
      'departureTime': (schedule?.time.contains(':') ?? false)
          ? schedule!.time.substring(0, 5)
          : 'N/A',
      'arrivalTime': 'TBA',
      'seatNumber': seatNumber ?? 'N/A',
      'scheduleDate': (() {
        try {
          final parsed = DateTime.parse(schedule?.date ?? '');
          return DateFormat('dd MMM, yyyy').format(parsed).toUpperCase();
        } catch (_) {
          return 'Date Unknown';
        }
      })(),
    };
  }
}
