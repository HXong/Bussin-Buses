import 'package:bussin_buses/pages/Authentication/login_page.dart';
import 'package:bussin_buses/pages/home_page_commuter.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/home_page_driver.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<String?> getUserType(String userId) async {
    try {
      final response =
          await Supabase.instance.client
              .from('profiles')
              .select('user_type')
              .eq('id', userId)
              .single();
      if (response == null) {
        return null;
      }
      return response['user_type'] as String?;
    } catch (e) {
      print('Error getting user type: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          String userId = session.user.id;
          return FutureBuilder<String?>(
            future: getUserType(userId),
            builder: (context, userTypeSnapshot) {
              if (userTypeSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final userType = userTypeSnapshot.data;

              if (userType == 'commuter') {
                return HomePageCommuter();
              } else if (userType == 'driver') {
                return HomePageDriver();
              } else {
                return LoginPage();
              }
            },
          );
        } else {
          return LoginPage();
        }
      },
    );
  }
}
