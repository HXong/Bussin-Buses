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

  void _onScheduleSelected(int id) {
    setState(() {
      selectedScheduleId = id;
      _selectedIndex = 1; // switch to Booking tab
    });
  }
  
  void _onBookingSelected(int id) {
    setState(() {
      selectedBookingId = id;
      _selectedIndex = 3; // switch to Live Location tab
    });
  }
  
  void _onUpcomingBookingTap() {
    setState(() {
      _selectedIndex = 2; // switch to Ticket tab
    });
  }
  
  void _onSearchSubmitted(String pickup, String destination, String date, String time) {
    // If time is provided, go directly to results
    // Otherwise, go to search screen to complete the form
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
      selectedScheduleId != null
          ? BookingNav(scheduleId: selectedScheduleId!)
          : Center(child: Text("No schedule selected")),
      TicketNav(onBookingSelected: _onBookingSelected),
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