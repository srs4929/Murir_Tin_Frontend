import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/QRcode.dart';

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String? selectedPayment;

  final TextEditingController pinController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  void _showPinDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              "Enter Payment Details",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Enter your phone number",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color.fromARGB(255, 2, 25, 44),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: TextField(
                    controller: phoneController,

                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 3,
                      ),
                      hintText: "01XXXXXXXXX",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Enter your pin",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color.fromARGB(255, 2, 25, 44),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: TextField(
                    controller: pinController,

                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        vertical:10,
                        horizontal: 3,
                      ),
                      hintText: "XXXXXX",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close only PIN dialog
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red, // Red text
                  textStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  String pin = pinController.text.trim();
                  String phone = phoneController.text.trim();

                  if (pin.length != 6 || phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please enter valid PIN and phone number",
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context); // Close PIN dialog
                  Navigator.pop(context); // Close PaymentDialog

                  // Navigate to QR code page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Qrcode()),
                  );
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Color(0xFF14213D)),
                  minimumSize: MaterialStateProperty.all(
                    Size(60, 10),
                  ), // always black
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  padding: MaterialStateProperty.all(
                    EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  elevation: MaterialStateProperty.all(5),
                ),
                child: const Text("Confirm"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Select Payment Option",
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<String>(
            title: const Text("Bkash"),
            value: "Bkash",
            groupValue: selectedPayment,
            onChanged: (value) {
              setState(() {
                selectedPayment = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text("Nagad"),
            value: "Nagad",
            groupValue: selectedPayment,
            onChanged: (value) {
              setState(() {
                selectedPayment = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text("Rocket"),
            value: "Rocket",
            groupValue: selectedPayment,
            onChanged: (value) {
              setState(() {
                selectedPayment = value;
              });
            },
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed:
                selectedPayment == null
                    ? null
                    : () {
                      Navigator.pop(context);
                      _showPinDialog();
                    },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Color(0xFF14213D)),
              minimumSize: MaterialStateProperty.all(
                Size(200, 10),
              ),
              foregroundColor: MaterialStateProperty.all(Colors.white),
              padding: MaterialStateProperty.all(
                EdgeInsets.symmetric(horizontal: 15, vertical: 9),
              ),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              elevation: MaterialStateProperty.all(5),
            ),
            child: const Text("Pay", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
