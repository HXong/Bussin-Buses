import 'package:bussin_buses/auth/auth_service.dart';
import 'package:bussin_buses/component/button_component.dart';
import 'package:bussin_buses/component/inputText_component.dart';
import 'package:flutter/material.dart';

class ForgetpasswordPage extends StatefulWidget {
  const ForgetpasswordPage({super.key});

  @override
  State<ForgetpasswordPage> createState() => _ForgetpasswordPageState();
}

class _ForgetpasswordPageState extends State<ForgetpasswordPage> {
  final authService = AuthService();

  final emailController = TextEditingController();

  Future<void> forgetPassword() async {
    final email = emailController.text;

    try {
      // ForgetPassword Function from auth_service
      await authService.forgetPassword(email);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Forget Password")));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
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
              const SizedBox(height: 50),

              //logo
              const Icon(Icons.directions_bus_filled, size: 100),

              const SizedBox(height: 50),

              // Bussin Busses
              const Text(
                "Forget your password?",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Enter your email address and we'll send you a password reset link",
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
              ),

              const  SizedBox(height: 50),

              // email
              InputtextComponent(
                controller: emailController,
                hintText: "Email",
                obscureText: false,
                action: TextInputAction.done,
              ),

              const Spacer(),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // forget password button
            ButtonComponent(
              buttonText: "Send LInk",
              onTap: () {
                forgetPassword();
              },
            ),
          ],
        ),
      ),
    );
  }
}
