import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/Component.dart';
import 'package:murir_tin/CustomBookText.dart';
import 'package:murir_tin/CustomTextInput.dart';

class Bookticket extends StatelessWidget {
  const Bookticket({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GAppBar(title: "Book Ticket"),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 62, 87, 141), Color(0xFF4B6EAF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    "Book your ticket",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Confirm your seat and have a safe journey",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomBookText(
                    label: "From",
                    hint: "Enter your current locaation",
                    prefixIcon: Icons.my_location,
                  ),
                  const SizedBox(height:20),
                  CustomBookText(
                    label: "To",
                    hint: "Enter your desire location",
                    prefixIcon: Icons.location_on,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
