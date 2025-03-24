import 'package:flutter/material.dart';
import '../viewmodels/commuter_viewmodel.dart';
import '../services/mock_commuter_service.dart';

class BusResultsScreen extends StatefulWidget {
  const BusResultsScreen({Key? key}) : super(key: key);

  @override
  State<BusResultsScreen> createState() => _BusResultsScreenState();
}

class _BusResultsScreenState extends State<BusResultsScreen> {
  final CommuterViewModel _viewModel = CommuterViewModel(MockCommuterService());
  List<Map<String, dynamic>> _buses = [];
  bool _isLoading = true;
  String _from = '';
  String _to = '';
  DateTime? _date;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _from = args['from'] as String;
      _to = args['to'] as String;
      _date = args['date'] as DateTime;
      _searchBuses();
    }
  }

  Future<void> _searchBuses() async {
    try {
      final buses = await _viewModel.searchBuses(
        from: _from,
        to: _to,
        date: _date!,
      );
      setState(() {
        _buses = buses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching buses: ${e.toString()}')),
      );
    }
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$formattedHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Buses'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Search summary
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_from to $_to',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_date?.day}/${_date?.month}/${_date?.year}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Change'),
                ),
              ],
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  '${_buses.length} buses found',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Text('Sort by: '),
                DropdownButton<String>(
                  value: 'Departure',
                  items: const [
                    DropdownMenuItem(
                      value: 'Departure',
                      child: Text('Departure'),
                    ),
                    DropdownMenuItem(
                      value: 'Price',
                      child: Text('Price'),
                    ),
                    DropdownMenuItem(
                      value: 'Duration',
                      child: Text('Duration'),
                    ),
                  ],
                  onChanged: (value) {
                    // Implement sorting logic
                  },
                ),
              ],
            ),
          ),

          // Bus list
          Expanded(
            child: _buses.isEmpty
                ? const Center(
              child: Text(
                'No buses found for this route and date.',
                style: TextStyle(fontSize: 16),
              ),
            )
                : ListView.builder(
              itemCount: _buses.length,
              itemBuilder: (context, index) {
                final bus = _buses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Bus company and number
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_bus,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Bus ${bus['bus_number']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '\$${bus['price'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Time and route
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatTime(bus['departure_time']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bus['from_location'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.grey,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatTime(bus['arrival_time']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bus['to_location'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Available seats and book button
                        Row(
                          children: [
                            Text(
                              '${bus['available_seats']} seats available',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/bus_details',
                                  arguments: {'bus_id': bus['id']},
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              child: const Text('Select'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

