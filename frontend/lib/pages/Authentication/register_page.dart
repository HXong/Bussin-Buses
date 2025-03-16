import 'package:bussin_buses/component/button_component.dart';
import 'package:bussin_buses/component/inputText_component.dart';
import 'package:bussin_buses/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

const List<Widget> Users = <Widget>[
  Row(children: [Icon(Icons.person), SizedBox(width: 5,), Text('Commuter')]),
  Row(children: [Icon(Icons.directions_bus_filled_outlined), SizedBox(width: 5,), Text('Driver')])
];

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final List<bool> _selectedUser = <bool>[true, false];

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // show success snackbar
      if (authViewModel.successMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authViewModel.successMsg!)),
        );
        authViewModel.clearMsg();
        Navigator.pop(context);
      }

      // show error snackbar
      if (authViewModel.errorMsg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authViewModel.errorMsg!)),
        );
        authViewModel.clearMsg();
      }
    });
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),

              //logo
              const Icon(Icons.directions_bus_filled, size: 100),

              const SizedBox(height: 20),

              // Bussin Busses
              const Text(
                "Register",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 30),

              //name
              InputtextComponent(
                controller: nameController,
                hintText: "Name",
                obscureText: false,
                action: TextInputAction.next,
              ),

              const SizedBox(height: 30),

              //email
              InputtextComponent(
                controller: emailController,
                hintText: "Email",
                obscureText: false,
                action: TextInputAction.next,
              ),

              const SizedBox(height: 30),

              //password
              InputtextComponent(
                controller: passwordController,
                hintText: "Password",
                obscureText: true,
                action: TextInputAction.next,
              ),

              const SizedBox(height: 30),

              //confirm password
              InputtextComponent(
                controller: confirmPasswordController,
                hintText: "Confirm Password",
                obscureText: true,
                action: TextInputAction.done,
              ),

              const SizedBox(height: 30),

              ToggleButtons(
                direction: Axis.horizontal,
                  onPressed: (int index) {
                  setState(() {
                    for (int i = 0; i < _selectedUser.length; i++) {
                      _selectedUser[i] = i == index;
                    }
                  });
                  },
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  selectedBorderColor: Colors.lightBlueAccent,
                  selectedColor: Colors.white70,
                  fillColor: Colors.lightBlueAccent[200],
                  color: Colors.lightBlueAccent[400],
                  constraints: const BoxConstraints(minHeight: 40.0, minWidth: 150.0),
                  children: Users,
                  isSelected: _selectedUser
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // register button
            ButtonComponent(
              buttonText: "Register",
              onTap: () {
                if (!authViewModel.isLoading) {
                  final username = nameController.text;
                  final email = emailController.text;
                  final password = passwordController.text;
                  final confirmPassword = confirmPasswordController.text;
                  final userType = _selectedUser[0] ? 'commuter' : 'driver';

                  if (password.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Password must be at least 6 characters long")),
                    );
                    return;
                  }

                  if (password != confirmPassword) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Passwords don't match")),
                    );
                    return;
                  }

                  authViewModel.signUp(email, password, username, userType);
                }
              },
            ),

            // not a member? button
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Sign in",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
