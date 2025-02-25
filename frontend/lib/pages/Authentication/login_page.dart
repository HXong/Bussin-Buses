import 'package:bussin_buses/auth/auth_service.dart';
import 'package:bussin_buses/component/button_component.dart';
import 'package:bussin_buses/component/inputText_component.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> signIn() async {
    final email = emailController.text;
    final password = passwordController.text;

    try {
      // SignIn Function from auth_service
      await authService.signIn(email, password);
      ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text("Successfully Login")));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 50,),

              //logo
              const Icon(Icons.directions_bus_filled, size: 100),

              const SizedBox(height: 50),

              // Bussin Busses
              const Text(
                "Login",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 50),

              // email
              InputtextComponent(
                controller: emailController, 
                hintText: "Email", 
                obscureText: false,
                action: TextInputAction.next,
              ),

              const SizedBox(height: 50),

              // password
              InputtextComponent(
                controller: passwordController,
                hintText: "Password",
                obscureText: true,
                action: TextInputAction.done,
                ),

              const SizedBox(height: 15),

              //forget password
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/forget');
                      },
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),

              // const Spacer(),

            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              // sign in button
              ButtonComponent(
                buttonText: "Login",
                onTap: () {
                  signIn();
                },
              ),

              // not a member? button
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Not a member?"),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, "/register");
                      },
                      child: const Text(
                        "Register now",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],),
        ),
    );
  }
}
