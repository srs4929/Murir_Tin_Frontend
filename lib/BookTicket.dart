import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:murir_tin/Checkout.dart';
import 'package:murir_tin/Component.dart';
import 'package:murir_tin/CustomBookText.dart';
import 'package:murir_tin/QRcode.dart';
import 'package:murir_tin/api.dart';

class Bookticket extends StatefulWidget {
  const Bookticket({super.key});

  @override
  State<Bookticket> createState() => _BookticketState();
}

class _BookticketState extends State<Bookticket> {
  final TextEditingController ticketController = TextEditingController();
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  int? _ticketCount;
  double? _totalCost;
  String? _bookingId;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<String?> _getJwtToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      print('DEBUG: JWT Token is null or empty. User might not be logged in.');
      _showErrorDialog('You are not logged in. Please log in to book tickets.');
      return null;
    } else {
      print('DEBUG: Retrieved JWT Token: $token');
      return token;
    }
  }

  Future<void> bookTickets() async {
    final from = fromController.text.trim();
    final to = toController.text.trim();
    final count = int.tryParse(ticketController.text.trim()) ?? 0;

    if (from.isEmpty || to.isEmpty || count <= 0) {
      _showErrorDialog("Please fill all fields correctly.");
      return;
    }

    if (count > 4) {
      _showErrorDialog("You cannot book more than 4 seats.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Booking tickets..."),
          ],
        ),
      ),
    );

    try {
      final token = await _getJwtToken();
      if (token == null) {
        Navigator.pop(context);
        return;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse(ticket_book_endpoint),
        headers: headers,
        body: json.encode({
          'from_location': from,
          'to_location': to,
          'ticket_count': count,
        }),
      );

      Navigator.pop(context); // Dismiss loading

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print("DEBUG: Booking response = $responseData");

        setState(() {
          _ticketCount = responseData['ticket_count'];
          _totalCost = (responseData['total_cost'] as num).toDouble();
          _bookingId = responseData['booking_id'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Booking successful! Total cost: ৳$_totalCost"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['detail'] ?? "An unknown error occurred.";
        _showErrorDialog(errorMessage);
      }
    } on http.ClientException catch (e) {
      Navigator.pop(context);
      _showErrorDialog("Network error: Failed to connect to the server. Is FastAPI running? (${e.message})");
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog("An unexpected error occurred: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: const GAppBar(title: "Book Ticket"),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 160),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 62, 87, 141),
                          Color(0xFF4B6EAF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
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
                          ),
                        ),
                        const SizedBox(height: 20),

                        // From input
                        CustomBookText(
                          label: "From",
                          hint: "Enter your current location",
                          prefixIcon: Icons.my_location,
                          controller: fromController,
                        ),
                        const SizedBox(height: 20),

                        // To input
                        CustomBookText(
                          label: "To",
                          hint: "Enter your desired location",
                          prefixIcon: Icons.location_on,
                          controller: toController,
                        ),
                        const SizedBox(height: 22),

                        // Number of tickets
                        CustomBookText(
                          label: "Number of Ticket",
                          hint: "Enter the number of ticket",
                          prefixIcon: Icons.confirmation_number,
                          controller: ticketController,
                        ),
                        const SizedBox(height: 22),

                        if (_totalCost != null)
                          Text(
                            "Total cost: ৳$_totalCost",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        const SizedBox(height: 10),

                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.85,
                          child: ElevatedButton(
                            onPressed: () async {
                              await bookTickets();
                            },
                            child: Text(
                              "Confirm",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom tap here to pay button
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {
                if (_ticketCount != null && _totalCost != null && _bookingId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Checkout(
                        totalCost: _totalCost ?? 0.0,
                        ticketCount: _ticketCount ?? 0,
                        bookingId: _bookingId ?? "",
                      ),
                    ),
                  );
                } else {
                  _showErrorDialog("Please confirm your booking first.");
                }
              },
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(1050),
                    topRight: Radius.circular(1050),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Tap Here to pay',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

