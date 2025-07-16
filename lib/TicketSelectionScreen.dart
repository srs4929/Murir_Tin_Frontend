import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:murir_tin/Component.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TicketSelectionScreen extends StatefulWidget {
  final String username;

  const TicketSelectionScreen({super.key, required this.username});

  @override
  State<TicketSelectionScreen> createState() => _TicketSelectionScreenState();
}

class _TicketSelectionScreenState extends State<TicketSelectionScreen> {
  final supabase = Supabase.instance.client;
  String? selectedTicketId;
  Map<String, dynamic>? selectedTicket;

  Future<List<Map<String, dynamic>>> fetchUserTickets() async {
    try {
      final userProfileResponse =
          await supabase
              .from('user_profiles')
              .select('id')
              .eq('username', widget.username)
              .single();
      final userId = userProfileResponse['id'];

      final ticketsResponse = await supabase
          .from('ticket_booking')
          .select()
          .eq('user_id', userId)
          .order('booking_time', ascending: false);

      return ticketsResponse;
    } catch (e) {
      print('Error fetching tickets: $e');
      return [];
    }
  }

  String _getTicketId(Map<String, dynamic> ticket) {
    if (ticket['booking_id'] != null) {
      return ticket['booking_id'].toString();
    } else if (ticket['id'] != null) {
      return ticket['id'].toString();
    } else if (ticket['ticket_id'] != null) {
      return ticket['ticket_id'].toString();
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final middleBlueColor = Color(0xFF4B6EAF);
    final darkBlueColor = Color(0xFF14213D);

    return Scaffold(
      appBar: GAppBar(title: "Select Ticket"),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.blue.shade50.withOpacity(0.1)],
          ),
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [darkBlueColor, middleBlueColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: middleBlueColor.withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.airplane_ticket_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Your Ticket',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Choose the ticket you want to complain about',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tickets List
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchUserTickets(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              middleBlueColor,
                            ),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Loading your tickets...',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: darkBlueColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: Colors.red.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Error loading tickets',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please try again later',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final tickets = snapshot.data!;

                  if (tickets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No Tickets Found',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'You need to book a ticket first before submitting a complaint',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      final ticketId = _getTicketId(ticket);
                      final isSelected = selectedTicketId == ticketId;

                      // Parse booking time
                      final bookingDateTime = DateTime.parse(
                        ticket['booking_time'],
                      );
                      final formattedDate = DateFormat(
                        'MMM dd, yyyy',
                      ).format(bookingDateTime);
                      final formattedTime = DateFormat.jm().format(
                        bookingDateTime,
                      );

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTicketId = ticketId;
                            selectedTicket = ticket;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  isSelected
                                      ? [
                                        middleBlueColor.withOpacity(0.1),
                                        Colors.blue.shade50.withOpacity(0.3),
                                      ]
                                      : [Colors.white, Colors.grey.shade50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? middleBlueColor.withOpacity(0.5)
                                      : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    isSelected
                                        ? middleBlueColor.withOpacity(0.2)
                                        : Colors.grey.shade200,
                                spreadRadius: 0,
                                blurRadius: isSelected ? 15 : 10,
                                offset: Offset(0, isSelected ? 8 : 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Header with ticket info
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors:
                                        isSelected
                                            ? [middleBlueColor, darkBlueColor]
                                            : [
                                              Colors.grey.shade600,
                                              Colors.grey.shade700,
                                            ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.confirmation_number_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ticket ID: $ticketId',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '$formattedDate • $formattedTime',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check_rounded,
                                          color: middleBlueColor,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Trip details
                              Padding(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    // Route
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'FROM',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade500,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                ticket['from_location'] ??
                                                    'Unknown',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: darkBlueColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Icon(
                                            Icons.arrow_forward_rounded,
                                            color: middleBlueColor,
                                            size: 24,
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'TO',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade500,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                ticket['to_location'] ??
                                                    'Unknown',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: darkBlueColor,
                                                ),
                                                textAlign: TextAlign.end,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 20),

                                    // Ticket details
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: middleBlueColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .confirmation_number_outlined,
                                                  color: middleBlueColor,
                                                  size: 20,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Tickets',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  '${ticket['ticket_count'] ?? 0}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: middleBlueColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.payments_rounded,
                                                  color: Colors.green.shade600,
                                                  size: 20,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Total Cost',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  '৳${ticket['total_cost'] ?? 0}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        Colors.green.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Confirm Selection Button
            if (selectedTicket != null)
              Container(
                padding: EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: middleBlueColor.withOpacity(0.3),
                        spreadRadius: 0,
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'ticketId': selectedTicketId,
                        'ticketData': selectedTicket,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: middleBlueColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Confirm Selection',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
