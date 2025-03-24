import 'package:flutter/material.dart';
import '../viewmodels/commuter_viewmodel.dart';
import '../services/mock_commuter_service.dart';

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({Key? key}) : super(key: key);

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final CommuterViewModel _viewModel = CommuterViewModel(MockCommuterService());
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  bool _isCancelling = false;
  bool _isCheckingIn = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      final bookingId = args['booking_id'] as String;
      _loadBookingDetails(bookingId);
    }
  }

  Future<void> _loadBookingDetails(String bookingId) async {
    try {
      final booking = await _viewModel.getBookingDetails(bookingId);
      setState(() {
        _booking = booking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading booking details: ${e.toString()}')),
      );
    }
  }

  Future<void> _cancelBooking() async {
    if (_booking == null) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      final success = await _viewModel.cancelBooking(_booking!['id']);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
        Navigator.pushReplacementNamed(context, '/booking_canceled');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel booking')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling booking: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isCancelling = false;
      });
    }
  }

  Future<void> _checkIn() async {
    if (_booking == null) return;

    setState(() {
      _isCheckingIn = true;
    });

    try {
      await _viewModel.checkInBooking(_booking!['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in successful')),
      );
      // Reload booking details to update status
      await _loadBookingDetails(_booking!['id']);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking in: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isCheckingIn = false;
      });
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
        title: const Text('Booking Details'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
          ? const Center(child: Text('Booking not found'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking status
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: _booking!['status'] == 'confirmed'
                    ? Colors.green.shade50
                    : _booking!['status'] == 'cancelled'
                    ? Colors.red.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _booking!['status'] == 'confirmed'
                        ? Icons.check_circle
                        : _booking!['status'] == 'cancelled'
                        ? Icons.cancel
                        : Icons.confirmation_number,
                    color: _booking!['status'] == 'confirmed'
                        ? Colors.green
                        : _booking!['status'] == 'cancelled'
                        ? Colors.red
                        : Colors.blue,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _booking!['status'] == 'confirmed'
                              ? 'Booking Confirmed'
                              : _booking!['status'] == 'cancelled'
                              ? 'Booking Cancelled'
                              : 'Checked In',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _booking!['status'] == 'confirmed'
                              ? 'Your booking is confirmed. You can check in 24 hours before departure.'
                              : _booking!['status'] == 'cancelled'
                              ? 'This booking has been cancelled.'
                              : 'You have successfully checked in for this trip.',
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Trip details
            const Text(
              'Trip Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Date and bus number
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _booking!['buses']['date'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.directions_bus,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bus ${_booking!['buses']['bus_number']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Route and time
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatTime(_booking!['buses']['departure_time']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _booking!['buses']['from_location'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.grey,
                            ),
                            Text(
                              '4h 00m',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatTime(_booking!['buses']['arrival_time']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _booking!['buses']['to_location'],
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Passenger details
            const Text(
              'Passenger Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.person,
                      label: 'Name',
                      value: _booking!['passenger_name'],
                    ),
                    const Divider(),
                    _buildDetailRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: _booking!['passenger_email'],
                    ),
                    const Divider(),
                    _buildDetailRow(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: _booking!['passenger_phone'],
                    ),
                    const Divider(),
                    _buildDetailRow(
                      icon: Icons.event_seat,
                      label: 'Seat',
                      value: _booking!['seat_number'],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment details
            const Text(
              'Payment Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.receipt,
                      label: 'Booking ID',
                      value: _booking!['id'],
                    ),
                    const Divider(),
                    _buildDetailRow(
                      icon: Icons.attach_money,
                      label: 'Amount Paid',
                      value: '\$${_booking!['price'].toStringAsFixed(2)}',
                    ),
                    const Divider(),
                    _buildDetailRow(
                      icon: Icons.payment,
                      label: 'Payment Method',
                      value: 'Credit Card',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            if (_booking!['status'] == 'confirmed')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCancelling ? null : _cancelBooking,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: _isCancelling
                          ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Cancelling...'),
                        ],
                      )
                          : const Text(
                        'Cancel Booking',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCheckingIn ? null : _checkIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: _isCheckingIn
                          ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Checking in...'),
                        ],
                      )
                          : const Text('Check In'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

