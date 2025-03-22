import 'package:flutter/material.dart';

class AccountNav extends StatefulWidget {
  const AccountNav({super.key});

  @override
  State<AccountNav> createState() => _AccountNavState();
}

class _AccountNavState extends State<AccountNav> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Text("Account Page Testing")
        ],
      ),
    );
  }
}
