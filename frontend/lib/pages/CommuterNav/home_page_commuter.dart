// lib/pages/CommuterNav/home_page_commuter.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:bussin_buses/services/auth_service.dart';
import 'package:bussin_buses/pages/CommuterNav/account_nav.dart';
import 'package:bussin_buses/pages/CommuterNav/booking_nav.dart';
import 'package:bussin_buses/pages/CommuterNav/home_nav.dart';
import 'package:bussin_buses/pages/CommuterNav/ticket_nav.dart';
import 'package:bussin_buses/pages/CommuterNav/live_location_nav.dart';
import './bus_search_screen.dart';
import './bus_results_screen.dart';

/// Main commuter home page with bottom navigation
class HomePageCommuter extends StatefulWidget {
  const HomePageCommuter({super.key});

  @override
  State<HomePageCommuter> createState() => _HomePageCommuterState();
}

class _HomePageCommuterState extends State<HomePageCommuter> {
  final authService = AuthService();
  int _selectedIndex = 0;
  int? selectedScheduleId;
  int? selectedBookingId;

  /// Handles when a schedule is selected from search results
  /// Updates state and switches to Booking tab
  void _onScheduleSelected(int id) {
    setState(() {
      selectedScheduleId = id;
      _selectedIndex = 1; // switch to Booking tab
    });
  }
  
  /// Handles when a booking is selected from tickets
  /// Updates state and switches to Live Location tab
  void _onBookingSelected(int id) {
    setState(() {
      selectedBookingId = id;
      _selectedIndex = 3; // switch to Live Location tab
    });
  }
  
  /// Handles tap on upcoming booking
  /// Switches to Ticket tab
  void _onUpcomingBookingTap() {
    setState(() {
      _selectedIndex = 2; // switch to Ticket tab
    });
  }
  
  /// Handles search form submission
  /// If time is provided, navigates directly to results
  /// Otherwise, navigates to search screen to complete the form
  void _onSearchSubmitted(String pickup, String destination, String date, String time) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => time.isNotEmpty
            ? BusResultsScreen(
                pickup: pickup,
                destination: destination,
                date: date,
                onScheduleSelected: _onScheduleSelected,
              )
            : BusSearchScreen(
                pickup: pickup,
                destination: destination,
                date: date,
                time: time,
                onScheduleSelected: _onScheduleSelected,
              ),
      ),
    );
  }

  /// Handles user logout
  /// Calls auth service to sign out
  Future<void> logout() async {
    try {
      await authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      HomeNav(
        onScheduleSelected: _onScheduleSelected,
        onSearchSubmitted: _onSearchSubmitted,
        onUpcomingBookingTap: _onUpcomingBookingTap,
      ),
      /// If a schedule is selected, show booking nav with that schedule
      /// Otherwise show a message to select a schedule
      selectedScheduleId != null
          ? BookingNav(scheduleId: selectedScheduleId!)
          : Center(child: Text("No schedule selected")),
      TicketNav(onBookingSelected: _onBookingSelected),
      /// If a booking is selected, show live location with that booking
      /// Otherwise show default live location
      selectedBookingId != null
          ? LiveLocationNav(bookingId: selectedBookingId)
          : const LiveLocationNav(),
      const AccountNav(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome Commuter"),
        actions: [
          GestureDetector(
            onTap: logout,
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
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus_filled), label: "Booking"),
          BottomNavigationBarItem(icon: Icon(Icons.airplane_ticket), label: "Ticket"),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "Live"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Account"),
        ],
      ),
    );
  }
}