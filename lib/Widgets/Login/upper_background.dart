import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UpperBackground extends StatelessWidget {
  final String primaryText;
  final String secondaryText;
  const UpperBackground({
    super.key,
    required this.primaryText,
    required this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF14213D), Color(0xFF4B6EAF)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 120.0, left: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              primaryText,
              style: GoogleFonts.poppins(
                fontSize: 35,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            Text(
              '" $secondaryText "',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
