import 'package:bussin_buses/auth/auth_service.dart';
import 'package:flutter/material.dart';

import '../component/button_component.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final authService = AuthService();

  Future<void> logout() async {
    try {
      await authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const Text(
            "Homepage",
            style: TextStyle(
              color: Colors.black,
              fontSize: 25,
              fontWeight: FontWeight.w500,
            ),
          ),

          ButtonComponent(
            buttonText: "Logout",
            onTap: () {
              logout();
            },
          ),
        ],
      ),
    );
  }
}