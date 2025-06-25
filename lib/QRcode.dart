import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/Component.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class Qrcode extends StatefulWidget {
  final int ticketCount;
  const Qrcode({Key? key, required this.ticketCount}) : super(key: key);

  @override
  State<Qrcode> createState() => _Qrcode();
}

class _Qrcode extends State<Qrcode> {
  String? username;
  bool isloading = true;

  @override
  void initState() {
    super.initState();
    fetchUsername();
  }

  Future<void> fetchUsername() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId != null) {
      final response =
          await supabase
              .from('user_profiles')
              .select('username')
              .eq('id', userId)
              .single();

      setState(() {
        username = response['username'];
        isloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GAppBar(title: "Ticket QR"),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Your Booked Ticket",
              style: GoogleFonts.poppins(
                fontSize: 22,
                color: Color(0xFF14213D),
              ),
            ),
            const SizedBox(height: 80),
            SizedBox(
              width: 250,
              height: 250,
              child: PrettyQrView.data(
                data: 'Booked by: $username',

                errorCorrectLevel: QrErrorCorrectLevel.M,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
