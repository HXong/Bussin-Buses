import 'package:flutter/material.dart';
import '../viewmodels/commuter_viewmodel.dart';
import '../services/mock_commuter_service.dart';
import 'package:provider/provider.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildMenuButton(
              title: 'Personal Information',
              onTap: () {
                Navigator.pushNamed(context, '/personal_info');
              },
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              title: 'Change Password',
              onTap: () {
                // Navigate to change password screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Change Password feature coming soon')),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              title: 'Past Trips',
              onTap: () {
                // Navigate to past trips screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Past Trips feature coming soon')),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              title: 'Upcoming Trips',
              onTap: () {
                Navigator.pushNamed(context, '/upcoming_bookings');
              },
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              title: 'Feedback',
              onTap: () {
                // Navigate to feedback screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feedback feature coming soon')),
                );
              },
            ),
            const Spacer(),
            _buildMenuButton(
              title: 'Log Out',
              onTap: () {
                _showLogoutConfirmation(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // Account tab
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'Bus',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'Tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/bus_search');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/upcoming_bookings');
              break;
            case 3:
            // Already on account
              break;
          }
        },
      ),
    );
  }

  Widget _buildMenuButton({
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Get the view model from provider
              final viewModel = Provider.of<CommuterViewModel>(context, listen: false);
              viewModel.signOut().then((_) {
                Navigator.pushReplacementNamed(context, '/home');
              });
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

