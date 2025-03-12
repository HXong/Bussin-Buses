import 'package:flutter/material.dart';

class TripList extends StatelessWidget {
  final List<dynamic> trips;
  final String noTripsMessage;
  final void Function(Map<String, dynamic>)? onTap;

  const TripList({
    Key? key,
    required this.trips,
    required this.noTripsMessage,
    this.onTap,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                    Text(trip['date'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(trip['status'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.red)),
                  ],
                ),

                // Time Range and Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(trip['start_time'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text('-----', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ),
                    ),
                    Text(trip['duration'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text('-----', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ),
                    ),
                    Text(trip['end_time'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),

                // Pickup & Destination
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(trip['pickup'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(trip['destination'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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