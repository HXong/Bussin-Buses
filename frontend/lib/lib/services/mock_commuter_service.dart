import 'commuter_service.dart';

class MockCommuterService implements CommuterService {
  // In-memory storage for mock data
  final Map<String, dynamic> _userProfile = {
    'id': 'mock-user-id',
    'full_name': 'matz chan',
    'email': 'matzchan@example.com',
    'phone': '+1234567890',
    'avatar_url': 'https://example.com/avatar.jpg',
  };

  final List<Map<String, dynamic>> _bookings = [
    {
      'id': '101',
      'user_id': 'mock-user-id',
      'bus_id': '1',
      'seat_number': 'A12',
      'passenger_name': 'matz',
      'passenger_email': 'matz@example.com',
      'passenger_phone': '+1234567890',
      'status': 'confirmed',
      'price': 45.99,
      'created_at': '2023-06-01T10:00:00.000Z',
      'buses': {
        'id': '1',
        'from_location': 'NTU',
        'to_location': 'SENGKANG',
        'date': '2025-03-02',
        'departure_time': '08:00:00',
        'arrival_time': '12:00:00',
        'bus_number': 'B-123',
      }
    },
    {
      'id': '102',
      'user_id': 'mock-user-id',
      'bus_id': '3',
      'seat_number': 'B08',
      'passenger_name': 'matz',
      'passenger_email': 'matz@example.com',
      'passenger_phone': '+1234567890',
      'status': 'confirmed',
      'price': 42.99,
      'created_at': '2023-06-02T14:30:00.000Z',
      'buses': {
        'id': '3',
        'from_location': 'NTU',
        'to_location': 'punggol',
        'date': '2025-01-12',
        'departure_time': '13:00:00',
        'arrival_time': '17:00:00',
        'bus_number': 'B-789',
      }
    },
  ];

  @override
  Future<Map<String, dynamic>> getUserProfile() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _userProfile;
  }

  @override
  Future<void> updateUserProfile({
    required String fullName,
    required String phone,
    String? profilePicture,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Update the mock profile
    _userProfile['full_name'] = fullName;
    _userProfile['phone'] = phone;
    if (profilePicture != null) {
      _userProfile['avatar_url'] = profilePicture;
    }

    return;
  }

  @override
  Future<void> signOut() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return;
  }

  @override
  Future<List<Map<String, dynamic>>> searchBuses({
    required String from,
    required String to,
    required DateTime date,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Return mock data with the actual search parameters
    return [
      {
        'id': '1',
        'from_location': from,
        'to_location': to,
        'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'departure_time': '08:00:00',
        'arrival_time': '12:00:00',
        'price': 45.99,
        'available_seats': 32,
        'bus_company_id': '1',
        'bus_number': 'B-123',
      },
      {
        'id': '2',
        'from_location': from,
        'to_location': to,
        'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'departure_time': '10:30:00',
        'arrival_time': '14:30:00',
        'price': 39.99,
        'available_seats': 15,
        'bus_company_id': '2',
        'bus_number': 'B-456',
      },
      {
        'id': '3',
        'from_location': from,
        'to_location': to,
        'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'departure_time': '13:00:00',
        'arrival_time': '17:00:00',
        'price': 42.99,
        'available_seats': 25,
        'bus_company_id': '1',
        'bus_number': 'B-789',
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> getBusDetails(String busId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return mock data
    return {
      'id': busId,
      'from_location': 'ntu',
      'to_location': 'sengkang',
      'date': '2023-06-15',
      'departure_time': '08:00:00',
      'arrival_time': '12:00:00',
      'price': 45.99,
      'available_seats': 32,
      'bus_company_id': '1',
      'bus_number': 'B-123',
      'bus_companies': {
        'id': '1',
        'name': 'Express Transit',
        'logo_url': 'https://example.com/logo.png',
      }
    };
  }

  @override
  Future<Map<String, dynamic>> bookBus({
    required String busId,
    required String seatNumber,
    required String passengerName,
    required String passengerEmail,
    required String passengerPhone,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    // Create a new booking
    final newBooking = {
      'id': 'booking-${DateTime.now().millisecondsSinceEpoch}',
      'user_id': 'mock-user-id',
      'bus_id': busId,
      'seat_number': seatNumber,
      'passenger_name': passengerName,
      'passenger_email': passengerEmail,
      'passenger_phone': passengerPhone,
      'status': 'confirmed',
      'price': 45.99,
      'created_at': DateTime.now().toIso8601String(),
      'buses': await getBusDetails(busId),
    };

    // Add to bookings list
    _bookings.add(newBooking);

    return newBooking;
  }

  @override
  Future<List<Map<String, dynamic>>> getUpcomingBookings() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 700));

    // Return the mock bookings
    return _bookings.where((booking) => booking['status'] != 'cancelled').toList();
  }

  @override
  Future<Map<String, dynamic>> getBookingDetails(String bookingId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Find the booking
    final booking = _bookings.firstWhere(
          (b) => b['id'] == bookingId,
      orElse: () => throw Exception('Booking not found'),
    );

    return booking;
  }

  @override
  Future<bool> cancelBooking(String bookingId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      // Find the booking
      final bookingIndex = _bookings.indexWhere((b) => b['id'] == bookingId);
      if (bookingIndex == -1) {
        return false;
      }

      // Update the status
      _bookings[bookingIndex]['status'] = 'cancelled';

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> checkInBooking(String bookingId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Find the booking
    final bookingIndex = _bookings.indexWhere((b) => b['id'] == bookingId);
    if (bookingIndex == -1) {
      throw Exception('Booking not found');
    }

    // Update the status
    _bookings[bookingIndex]['status'] = 'checked_in';

    return;
  }
}

