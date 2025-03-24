import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/home_screen.dart';
import 'views/bus_search_screen.dart';
import 'views/bus_results_screen.dart';
import 'views/upcoming_bookings_screen.dart';
import 'views/booking_detail_screen.dart';
import 'views/booking_canceled_screen.dart';
import 'views/account_screen.dart';
import 'views/live_location_screen.dart';
import 'views/personal_info_screen.dart';
import 'services/mock_commuter_service.dart';
import 'viewmodels/commuter_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  // await Supabase.initialize(
  //   url: 'YOUR_SUPABASE_URL',
  //   anonKey: 'YOUR_SUPABASE_ANON_KEY',
  // );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use MockCommuterService for now
    final commuterService = MockCommuterService();

    return ChangeNotifierProvider<CommuterViewModel>(
      create: (_) => CommuterViewModel(commuterService),
      child: MaterialApp(
        title: 'Commuter',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/home',
        routes: {
          '/home': (context) => const HomeScreen(),
          '/bus_search': (context) => const BusSearchScreen(),
          '/bus_results': (context) => const BusResultsScreen(),
          '/upcoming_bookings': (context) => const UpcomingBookingsScreen(),
          '/booking_details': (context) => const BookingDetailsScreen(),
          '/booking_canceled': (context) => const BookingCanceledScreen(),
          '/account': (context) => const AccountScreen(),
          '/live_location': (context) => const LiveLocationScreen(),
          '/personal_info': (context) => const PersonalInfoScreen(),
        },
      ),
    );
  }
}

