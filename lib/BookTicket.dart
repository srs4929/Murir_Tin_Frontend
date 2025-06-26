import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/Component.dart';
import 'package:murir_tin/CustomBookText.dart';
import 'package:murir_tin/QRcode.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Bookticket extends StatefulWidget {
  const Bookticket({super.key});

  @override
  State<Bookticket> createState() => _BookticketState();
}

class _BookticketState extends State<Bookticket> {
  final TextEditingController ticketController = TextEditingController();
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();

  int? ticketCount;
  int? totalCost;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
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

  Future<void> bookTickets() async {
    final from = fromController.text.trim();
    final to = toController.text.trim();
    final count = int.tryParse(ticketController.text.trim()) ?? 0;

    if (from.isEmpty || to.isEmpty || count <= 0) {
      _showErrorDialog("Please fill all fields correctly.");
      return;
    }
    print('FROM: $from');
    print('TO: $to');
    print('--- Querying Supabase...');
    final response =
        await Supabase.instance.client
            .from('bus_routes')
            .select('price, id, available_seats')
            .eq('from_location', from)
            .eq('to_location', to)
            .maybeSingle();
    print('Response: $response');
    if (response == null) {
      _showErrorDialog("Route not found.");
      return;
    }

    final available = response['available_seats'] as int?;
    final price = response['price'] as int?;
    final routeId = response['id'] as int?;

    if (available == null || price == null || routeId == null) {
      _showErrorDialog("Incomplete route data.");
      return;
    }

    if (count > 4) {
      _showErrorDialog("You can not book more than 4 seats");
      return;
    }

    final total = count * price;

    // Insert booking
    final insertResponse = await Supabase.instance.client
        .from('ticket_booking')
        .insert({
          'route_id': routeId,
          'from_location': from,
          'to_location': to,
          'ticket_count': count,
          'total_price': total,
          'booking_time': DateTime.now().toIso8601String(),
        });

    if (insertResponse.error != null) {
      _showErrorDialog("Booking failed: ${insertResponse.error!.message}");
      return;
    }

    // Update available seats
    final updateResponse = await Supabase.instance.client
        .from('bus_routes')
        .update({'available_seats': available - count})
        .eq('id', routeId);

    if (updateResponse.error != null) {
      _showErrorDialog(
        "Failed to update seats: ${updateResponse.error!.message}",
      );
      return;
    }

    // Save values to state to display cost and prepare for payment
    setState(() {
      ticketCount = count;
      totalCost = total;
    });
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
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 62, 87, 141),
                          const Color(0xFF4B6EAF),
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

                        // Show total cost if booked
                        if (totalCost != null)
                          Text(
                            "Total cost: \$${totalCost.toString()}",
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
               
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Qrcode(),
                    ),
                  );
                /*else {
                  _showErrorDialog("Please confirm your booking first.");
                }*/
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
