import 'package:intl/intl.dart';

class DriverProfile {
  final String username;
  final String userType;
  final String createdAt;

  DriverProfile({
    required this.username,
    required this.userType,
    required this.createdAt,
  });

  // Factory constructor to create a DriverProfile instance from raw data
  factory DriverProfile.fromMap(Map<String, dynamic> profileData) {
    // Parse the date and format it
    DateTime dateTime = DateTime.parse(profileData['created_at']);
    String formattedDate = DateFormat('dd MMM yyyy').format(dateTime);

    return DriverProfile(
      username: profileData['username'] ?? 'unknown',
      userType: profileData['user_type'] ?? 'unknown',
      createdAt: formattedDate,
    );
  }

  // Method to convert the DriverProfile instance to a map
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'user_type': userType,
      'created_at': createdAt,
    };
  }
}
