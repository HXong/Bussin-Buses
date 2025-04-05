import 'package:bussin_buses/component/button_component.dart';
import 'package:flutter/material.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {


  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> commuter() async {
   Navigator.pushNamed(context, '/login');
  }

  Future<void> driver() async {
    Navigator.pushNamed(context, '/login');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 100,),

              //logo
              const Icon(Icons.directions_bus_filled, size: 100),

              const SizedBox(height: 50),

              // Bussin Busses
              const Text(
                "Bussin Buses",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 100),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ButtonComponent(buttonText: "Commuter", onTap: commuter),
                  const SizedBox(width: 20,),
                  ButtonComponent(buttonText: "Driver", onTap: driver),
                ],
              )


            ],
          ),
        ),
      ),
    );
  }
}
