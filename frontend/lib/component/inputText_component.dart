import 'package:flutter/material.dart';

class InputtextComponent extends StatelessWidget {

  final controller;
  final String hintText;
  final bool obscureText;

  const InputtextComponent({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.blue,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xffDDDADA),
            fontSize: 16
          ),
          contentPadding: const EdgeInsets.all(15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}