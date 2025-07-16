import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomBookText extends StatelessWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextEditingController? controller;
  const CustomBookText({
    super.key,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: Colors.white),
        labelStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        hintStyle: GoogleFonts.poppins(color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
