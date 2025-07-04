import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/Component.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'pdf_generator.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class Bookinghistory extends StatefulWidget {
  final String username;

  const Bookinghistory({Key? key, required this.username}) : super(key: key);

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
        .eq('user_id', userId);

    return bookingResponse as List<Map<String, dynamic>>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GAppBar(title: "Booking History"),
      body: Column(
        children: [
          //  Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by departure or destination...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          //Booking List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchBookingHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                  return const Center(child: Text('No booking history found.'));
                }

                return ListView.builder(
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    final bookingDateTime = DateTime.parse(
                      booking['booking_time'],
                    );
                    final formattedDate = DateFormat.yMMMd().format(
                      bookingDateTime,
                    );
                    final formattedTime = DateFormat.jm().format(
                      bookingDateTime,
                    );

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  'Departure: ${booking['from_location']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.flag, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  'Destination: ${booking['to_location']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Date: $formattedDate',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Time: $formattedTime',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.confirmation_number, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Tickets: ${booking['ticket_count']}',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total Cost: ${booking['total_cost']}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color.fromARGB(255, 4, 44, 77),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final pdfDoc =
                                      PdfGenerator.generateBookingPdf(
                                        username:
                                            widget.username, // just username

                                        departure: booking['from_location'],
                                        destination: booking['to_location'],
                                        date: formattedDate,
                                        time: formattedTime,
                                        ticketCount: booking['ticket_count'],
                                        totalCost:
                                            booking['total_cost'].toString(),
                                      );

                                  await Printing.layoutPdf(
                                    onLayout:
                                        (PdfPageFormat format) async =>
                                            pdfDoc.save(),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF004080),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Print',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
