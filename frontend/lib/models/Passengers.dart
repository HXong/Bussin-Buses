class Passenger {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String seatNumber;
  final bool isCheckedIn;

  Passenger({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.seatNumber,
    required this.isCheckedIn,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: json['id'],
      name: json['name'],
      email: json['email'] ?? "",
      phone: json['phone'] ?? "",
      seatNumber: json['seat_number'],
      isCheckedIn: json['is_checked_in'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'seat_number': seatNumber,
      'is_checked_in': isCheckedIn,
    };
  }
}
