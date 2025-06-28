import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/Component.dart';
import 'package:url_launcher/url_launcher.dart';

class Aboutus extends StatelessWidget {
  const Aboutus({super.key});

  static final List<Map<String, String>> teamMembers = [
    {
      'name': 'Sumaiya Rahman Soma',
      'Batch': 'CSEDU29',
      'roll': '07',
      'email': 'rahmansoma2003@gmail.com',
      'image': 'assets/images/Soma.png',
    },
    {
      'name': 'Chowdhury Shafahid Rahman',
      'Batch': 'CSEDU29',
      'roll': '55',
      'email': 'shafahid666@gmail.com',
      'image': 'assets/images/Shafahid.jpeg',
    },
  ];

  void _launchEmail(BuildContext context, String email) async {
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $emailLaunchUri');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No email client found for $email')),
        );
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error launching email: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GAppBar(title: "About Us"),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          Center(
            child: Text(
              "Our Team",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          CarouselSlider.builder(
            itemCount: teamMembers.length,
            options: CarouselOptions(
              height: 360,
              enlargeCenterPage: true,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
            ),
            itemBuilder: (context, index, realIdx) {
              final member = teamMembers[index];

              return Card(
                key: ValueKey(member['email']),
                elevation: 5,
                color: Color(0xFF14213D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: AssetImage(member['image']!),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        member['name']!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        member['Batch']!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Roll: ${member['roll'] ?? ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _launchEmail(context, member['email']!),
                        child: Text(
                          member['email']!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color.fromARGB(255, 151, 166, 194),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 35),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "‘Murir Tin’ is a smart local bus app that uniquely combines color-coded routes, live GPS tracking, QR-based easy ticket booking, a complaint box—making daily transportation smoother, and easier while putting control back in the passenger's hands.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
