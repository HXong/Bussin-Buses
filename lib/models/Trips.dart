class Trip {
  final String scheduleId;
  final String driverName;
  final String date;
  final String startTime;
  final String endTime;
  final String duration;
  final String pickup;
  final String destination;
  final String status;
  final bool isJourneyStarted;

  Trip({
    required this.scheduleId,
    required this.driverName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.pickup,
    required this.destination,
    required this.status,
    required this.isJourneyStarted,
  });

  // Factory method to convert a map to a Trip object
  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      scheduleId: map['schedule_id'] ?? '',
      driverName: map['driver_name'] ?? 'Unknown Driver',
      date: map['date'] ?? '',
      startTime: map['start_time'] ?? '',
      endTime: map['end_time'] ?? '',
      duration: map['duration'] ?? '',
      pickup: map['pickup'] ?? '',
      destination: map['destination'] ?? '',
      status: map['status'] ?? '',
      isJourneyStarted: map['is_journey_started'] ?? false,
    );
  }

  // Convert Trip object to a Map (useful for debugging or saving to DB)
  Map<String, dynamic> toMap() {
    return {
      'schedule_id': scheduleId,
      'driver_name': driverName,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'duration': duration,
      'pickup': pickup,
      'destination': destination,
      'status': status,
      'is_journey_started': isJourneyStarted,
    };
  }
}
