import 'package:bussin_buses/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'DriverNav/account_nav.dart';
import 'DriverNav/home_nav.dart';
import 'DriverNav/ride_nav.dart';
import 'DriverNav/schedule_nav.dart';

class HomePageDriver extends StatefulWidget {
  @override
  State<HomePageDriver> createState() => _HomePageDriverState();
}

class _HomePageDriverState extends State<HomePageDriver> {
  final authService = AuthService();
  int _selectedIndex = 0;

  Future<void> logout() async {
    try {
      await authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  final List<Widget> widgetOptions = const <Widget>[
    HomeNav(),
    ScheduleNav(),
    RideNav(),
    AccountNav(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome Back Bob"),
        actions: [
          GestureDetector(
            onTap: () {
              logout();
            },
            child: Container(
              margin: EdgeInsets.all(10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                'assets/icons/logout.svg',
                height: 30,
                width: 30,
              ),
            ),
          ),
        ],
      ),

      body: widgetOptions.elementAt(_selectedIndex),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus_filled), label: "Schedule"),
          BottomNavigationBarItem(icon: Icon(Icons.route), label: "Ride"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Account"),
        ],
      ),

    );
  }
}

