import 'package:flutter/material.dart';
import 'package:bkash/bkash.dart';
import 'package:murir_tin/QRcode.dart';

void onButtonTap(
  BuildContext context,
  String selected,
  double totalCost,
  String bookingId,
  int ticketCount,
) async {
  print("Selected payment method inside onTap: $selected");
  print("Total Cost: $totalCost");

  switch (selected) {
    case 'bkash':
      await bkashPayment(context, totalCost, bookingId, ticketCount);
      break;
    default:
      print("No Gateway Selected");
  }
}

final bKash = Bkash(logResponse: true);

Future<void> bkashPayment(
  BuildContext context,
  double totalCost,
  String bookingId,
  int ticketCount,
) async {
  try {
    double amount = totalCost;
    final merchantInvoiceNumber = "INV-123";

    final result = await bKash.pay(
      context: context,
      amount: amount,
      merchantInvoiceNumber: merchantInvoiceNumber,
    );

    _showDialog(
      // ignore: use_build_context_synchronously
      context,
      'Payment successful',
      'Transaction ID: ${result.trxId}',
      bookingId,
      ticketCount,
    );
  } on BkashFailure catch (e) {
    _showDialog(
      // ignore: use_build_context_synchronously
      context,
      'Payment failed',
      'Error: ${e.message}',
      bookingId,
      ticketCount,
    );
  }
}

void _showDialog(
  BuildContext context,
  String title,
  String message,
  String bookingId,
  int ticketCount,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog

              if (title == 'Payment successful') {
                // Navigate to the QRcode screen and pass the bookingId and ticketCount
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => Qrcode(
                          ticketId: bookingId, // Pass bookingId
                          ticketCount: ticketCount, // Pass ticketCount
                        ),
                  ),
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
