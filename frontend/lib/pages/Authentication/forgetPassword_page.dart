import 'package:bussin_buses/component/button_component.dart';
import 'package:bussin_buses/component/inputText_component.dart';
import 'package:bussin_buses/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ForgetpasswordPage extends StatefulWidget {
  const ForgetpasswordPage({super.key});

  @override
  State<ForgetpasswordPage> createState() => _ForgetpasswordPageState();
}

class _ForgetpasswordPageState extends State<ForgetpasswordPage> {

  final emailController = TextEditingController();

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
                if (!authViewModel.isLoading) {
                  authViewModel.forgetPassword(emailController.text);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
