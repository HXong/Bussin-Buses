import 'package:bussin_buses/viewmodels/auth_viewmodel.dart';
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
  int _selectedIndex = 0;

  final List<Widget> widgetOptions = const <Widget>[
    HomeNav(),
    ScheduleNav(),
    RideNav(),
    AccountNav(),
  ];

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // show error snackbar
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