class SeatManager {
  static final SeatManager _instance = SeatManager._internal();
  factory SeatManager() => _instance;

  SeatManager._internal();

  List<String> bookedSeats = []; // List to store booked seats
}

final seatManager = SeatManager();
