import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:murir_tin/Component.dart';
import 'package:murir_tin/QRcode.dart';
import 'package:murir_tin/pdf_generator.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Bookinghistory extends StatefulWidget {
  final String username;

  const Bookinghistory({super.key, required this.username});

  @override
  State<Bookinghistory> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<Bookinghistory> {
  final supabase = Supabase.instance.client;

  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<List<Map<String, dynamic>>> fetchBookingHistory() async {
    final userProfileResponse =
        await supabase
            .from('user_profiles')
            .select('id')
            .eq('username', widget.username)
            .single();
    final userId = userProfileResponse['id'];

    final bookingResponse = await supabase
        .from('ticket_booking')
        .select()
        .eq('user_id', userId)
        .order('booking_time', ascending: false);

    return bookingResponse;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GAppBar(title: "Booking History"),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by departure or destination...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: const Color(0xFF004080),
                    size: 22,
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),

          // Booking List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchBookingHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF004080),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading your booking history...',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final bookings = snapshot.data!;
                final filteredBookings =
                    bookings.where((booking) {
                      final departure =
                          booking['from_location'].toString().toLowerCase();
                      final destination =
                          booking['to_location'].toString().toLowerCase();
                      return departure.contains(_searchQuery) ||
                          destination.contains(_searchQuery);
                    }).toList();

                if (filteredBookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No booking history found',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try adjusting your search terms'
                              : 'Your past bookings will appear here',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    final bookingDateTime = DateTime.parse(
                      booking['booking_time'],
                    );
                    // Add 6 hours for GMT+6 timezone
                    final localDateTime = bookingDateTime.add(
                      Duration(hours: 6),
                    );
                    final formattedDate = DateFormat.yMMMd().format(
                      localDateTime,
                    );
                    final formattedTime = DateFormat.jm().format(localDateTime);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.grey.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                            spreadRadius: 0,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          children: [
                            // Header section with gradient
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(
                                      0xFF004080,
                                    ).withValues(alpha: 0.1),
                                    const Color(
                                      0xFF004080,
                                    ).withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.confirmation_number_rounded,
                                            color: const Color(0xFF004080),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Bus Ticket',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF004080),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Booking Confirmation',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Confirmed',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Booking details section
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // Route information container
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.location_on_rounded,
                                                color: Colors.green,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'From',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  Text(
                                                    booking['from_location'] ??
                                                        'Unknown',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Colors.grey.shade800,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF004080,
                                                ).withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Color(0xFF004080),
                                                size: 14,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    'To',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  Text(
                                                    booking['to_location'] ??
                                                        'Unknown',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Colors.grey.shade800,
                                                    ),
                                                    textAlign: TextAlign.end,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.location_on_rounded,
                                                color: Colors.red,
                                                size: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Date, Time, and Tickets info
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: IntrinsicHeight(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 100,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(
                                                  alpha: 0.05,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.blue.withValues(
                                                    alpha: 0.1,
                                                  ),
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .calendar_today_rounded,
                                                    color: Colors.blue.shade600,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Date',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  Text(
                                                    formattedDate,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Colors.grey.shade800,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 100,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withValues(
                                                  alpha: 0.05,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.orange
                                                      .withValues(alpha: 0.1),
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    color:
                                                        Colors.orange.shade600,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Time',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  Text(
                                                    formattedTime,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Colors.grey.shade800,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 100,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.withValues(
                                                  alpha: 0.05,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: Colors.purple
                                                      .withValues(alpha: 0.1),
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.confirmation_number,
                                                    color:
                                                        Colors.purple.shade600,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Tickets',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${booking['ticket_count'] ?? 0}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Colors.grey.shade800,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Cost information
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(
                                            0xFF004080,
                                          ).withValues(alpha: 0.05),
                                          const Color(
                                            0xFF004080,
                                          ).withValues(alpha: 0.02),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF004080,
                                        ).withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Total Cost',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  '৳${booking['total_cost'] ?? 0}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w800,
                                                    color: const Color(
                                                      0xFF004080,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.currency_exchange_rounded,
                                          color: const Color(
                                            0xFF004080,
                                          ).withValues(alpha: 0.6),
                                          size: 28,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Action buttons
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 140,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              String ticketId;
                                              if (booking['booking_id'] !=
                                                  null) {
                                                ticketId =
                                                    booking['booking_id']
                                                        .toString();
                                              } else if (booking['id'] !=
                                                  null) {
                                                ticketId =
                                                    booking['id'].toString();
                                              } else if (booking['ticket_id'] !=
                                                  null) {
                                                ticketId =
                                                    booking['ticket_id']
                                                        .toString();
                                              } else {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Invalid ticket ID format',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) => Qrcode(
                                                        ticketCount:
                                                            booking['ticket_count'] ??
                                                            0,
                                                        ticketId: ticketId,
                                                      ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF28A745,
                                              ),
                                              elevation: 4,
                                              shadowColor: const Color(
                                                0xFF28A745,
                                              ).withValues(alpha: 0.3),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.qr_code_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            label: Text(
                                              'See QR',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 140,
                                          child: ElevatedButton.icon(
                                            onPressed: () async {
                                              final pdfDoc =
                                                  PdfGenerator.generateBookingPdf(
                                                    username: widget.username,
                                                    departure:
                                                        booking['from_location'] ??
                                                        'Unknown',
                                                    destination:
                                                        booking['to_location'] ??
                                                        'Unknown',
                                                    date: formattedDate,
                                                    time: formattedTime,
                                                    ticketCount:
                                                        booking['ticket_count'] ??
                                                        0,
                                                    totalCost:
                                                        booking['total_cost']
                                                            ?.toString() ??
                                                        '0',
                                                  );

                                              await Printing.layoutPdf(
                                                onLayout:
                                                    (
                                                      PdfPageFormat format,
                                                    ) async => pdfDoc.save(),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF004080,
                                              ),
                                              elevation: 4,
                                              shadowColor: const Color(
                                                0xFF004080,
                                              ).withValues(alpha: 0.3),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.print_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            label: Text(
                                              'Print',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
        ],
      ),
    );
  }
}
