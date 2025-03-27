import 'package:flutter/material.dart';
import 'package:bussin_buses/models/Trips.dart';

class TripList extends StatelessWidget {
  final List<Trip> trips; // Change the type of trips to List<Trip>
  final String noTripsMessage;
  final void Function(Trip)? onTap;
  final void Function(Trip)? onLoadJourney;

  const TripList({
    Key? key,
    required this.trips,
    required this.noTripsMessage,
    this.onTap,
    this.onLoadJourney,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return trips.isEmpty
        ? Center(
      child: Text(
        noTripsMessage,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    )
        : ListView.builder(
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          color: Colors.grey.shade300,
          child: ListTile(
            contentPadding: const EdgeInsets.all(15),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      trip.date, // Accessing with dot notation
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      trip.status, // Accessing with dot notation
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: trip.status == 'CANCELLED'
                            ? Colors.red
                            : Colors.blue,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      trip.startTime, // Accessing with dot notation
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          '-----',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      trip.duration, // Accessing with dot notation
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          '-----',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      trip.endTime, // Accessing with dot notation
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      trip.pickup, // Accessing with dot notation
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      trip.destination, // Accessing with dot notation
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Driver Name: ${trip.driverName}', // Accessing with dot notation
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (onLoadJourney != null)
                      ElevatedButton(
                        onPressed: () => onLoadJourney!(trip),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF000066),
                          elevation: 1,
                          foregroundColor: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.white),
                            Text("Navigate", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: onTap != null
                ? IconButton(
              icon: const Icon(Icons.chevron_right, size: 30),
              onPressed: () => onTap!(trip),
            )
                : null,
          ),
        );
      },
    );
  }
}
