import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/QRcode.dart';
import 'package:murir_tin/Checkout.dart';

class PaymentDialog extends StatefulWidget {
  final int ticketCount;
  final String bookingId;
  final double totalCost;

  const PaymentDialog({
    Key? key,
    required this.ticketCount,
    required this.bookingId,
    required this.totalCost,
  }) : super(key: key);

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
                        vertical: 10,
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
                  Navigator.pop(context); 
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red, 
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

                  Navigator.pop(context); 
                  Navigator.pop(context); 


                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => Qrcode(
                            ticketCount: widget.ticketCount,
                            ticketId: widget.bookingId,
                          ),
                    ),
                  );
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Color(0xFF14213D)),
                  minimumSize: WidgetStateProperty.all(
                    Size(60, 10),
                  ), // always black
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                  padding: WidgetStateProperty.all(
                    EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  elevation: WidgetStateProperty.all(5),
                ),
                child: const Text("Confirm"),
              ),
            ],
          ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context,
    String name,
    String logoUrl,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blueAccent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha((0.2 * 255).toInt()),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.network(
              logoUrl,
              height: 35,
              width: 35,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.payment, size: 35);
              },
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.blueAccent,
            ),
          ],
        ),
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
          // bKash payment option
          _buildPaymentOption(
            context,
            'bKash',
            'https://freelogopng.com/images/all_img/1656234841bkash-icon-png.png',
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => Checkout(
                        totalCost: widget.totalCost,
                        ticketCount: widget.ticketCount,
                        bookingId: widget.bookingId,
                      ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Traditional payment options
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
              minimumSize: MaterialStateProperty.all(Size(200, 10)),
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
