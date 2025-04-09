import 'package:bussin_buses/viewmodels/auth_viewmodel.dart';
import 'package:bussin_buses/viewmodels/driver_viewmodel.dart';
import 'package:bussin_buses/viewmodels/journey_tracking_viewmodel.dart';
import 'package:bussin_buses/viewmodels/trip_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'account_nav.dart';
import 'home_nav.dart';
import 'ride_nav.dart';
import 'schedule_nav.dart';

class HomePageDriver extends StatefulWidget {
  @override
  State<HomePageDriver> createState() => _HomePageDriverState();
}

class _HomePageDriverState extends State<HomePageDriver> {
  final List<Widget> widgetOptions = const <Widget>[
    HomeNav(),
    ScheduleNav(),
    RideNav(),
    AccountNav(),
  ];

  @override
  Widget build(BuildContext context) {
    /// get reference to the providers injected into the app
    final authViewModel = Provider.of<AuthViewModel>(context);
    final driverViewModel = Provider.of<DriverViewModel>(context);
    final tripViewModel = Provider.of<TripViewModel>(context);
    final journeyTrackingViewModel = Provider.of<JourneyTrackingViewModel>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      /// show error snackbar
      if (authViewModel.errorMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authViewModel.errorMsg!)),
        );
        authViewModel.clearMsg();
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome Driver"),
        actions: [
          GestureDetector(
            onTap: () {
              tripViewModel.reset();
              journeyTrackingViewModel.reset();
              authViewModel.signOut();
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

      body: widgetOptions.elementAt(driverViewModel.selectedIndex),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: driverViewModel.selectedIndex,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (int index) {
          driverViewModel.setPageIndex(index);
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

