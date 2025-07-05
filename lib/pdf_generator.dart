import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGenerator {
  static pw.Document generateBookingPdf({
    required String username,
    required String departure,
    required String destination,
    required String date,
    required String time,
    required int ticketCount,
    required String totalCost,
  }) {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Booking History Title (centered)
            pw.Center(
              child: pw.Text(
                'Booking History',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.SizedBox(height: 80),

            // Username (left align, under title)
            pw.Text(
              'Username: $username',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),

            // Ticket Info in Table Format
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey),
              columnWidths: {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(3),
              },
              children: [
                buildRow('Departure', departure),
                buildRow('Destination', destination),
                buildRow('Date', date),
                buildRow('Time', time),
                buildRow('Tickets', '$ticketCount'),
                buildRow('Total Cost', totalCost),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  static pw.TableRow buildRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }
}



