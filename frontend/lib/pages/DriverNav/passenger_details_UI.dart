import 'package:bussin_buses/models/Passengers.dart';
import 'package:flutter/material.dart';

class PassengerList extends StatelessWidget {
  final List<Passenger> passengers;
  final String noPassengerMessage;

  const PassengerList({
    Key? key,
    required this.passengers,
    required this.noPassengerMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return passengers.isEmpty
        ? Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 200),
        child: Text(
          noPassengerMessage,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    )
        : Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: passengers.map((passenger) {
            final commuterName = passenger.name;
            final seatNumber = passenger.seatNumber;
            final isCheckedIn = passenger.isCheckedIn;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: isCheckedIn ? Colors.orange[700] : Colors.grey[600],
                        size: 25,
                      ),
                      const SizedBox(width: 10),
                      // Commuter name
                      Text(
                        commuterName.toString(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Text(
                    'Seat $seatNumber',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
