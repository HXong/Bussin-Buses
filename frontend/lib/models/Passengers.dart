/// Passenger model is used to store data about passengers in a particular driver's journey
class Passenger {
  final String id;
  final String name;
  final String seatNumber;
  final bool isCheckedIn;

  Passenger({
    required this.id,
    required this.name,
    required this.seatNumber,
    required this.isCheckedIn,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: json['id'],
      name: json['name'],
      seatNumber: json['seat_number'],
      isCheckedIn: json['is_checked_in'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'seat_number': seatNumber,
      'is_checked_in': isCheckedIn,
    };
  }
}
