import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/Models/model.dart';

class FormTextField extends StatefulWidget {
  final FormTextFieldModel textData;

  const FormTextField({super.key, required this.textData});

  @override
  State<FormTextField> createState() => _FormTextFieldState();
}

class _FormTextFieldState extends State<FormTextField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        TextField(
          controller: widget.textData.controller,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            labelText: widget.textData.label,
            hintText: widget.textData.hintText,
            hintStyle: GoogleFonts.poppins(color: Colors.grey),
            labelStyle: GoogleFonts.poppins(
              color: Color(0xFF14213D),
              fontWeight: FontWeight.bold,
            ),
            prefixIcon: Icon(widget.textData.icon, color: Color(0xFF14213D)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
