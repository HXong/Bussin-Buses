import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'login_page.dart';
import '../CommuterNav/home_page_commuter.dart';
import '../DriverNav/home_page_driver.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    if (authViewModel.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    /// load correct client based on whether userType is commuter/driver.
    /// Otherwise show the login page
    if (authViewModel.user != null) {
      if (authViewModel.userType == 'commuter') {
        return HomePageCommuter();
      } else if (authViewModel.userType == 'driver') {
        return HomePageDriver();
      } else {
        return LoginPage();
      }
    } else {
      return LoginPage();
    }
  }
}