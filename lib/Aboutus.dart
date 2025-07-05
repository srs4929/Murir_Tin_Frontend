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
      'name': 'Md. Ishrak Faisal',
      'Batch': 'CSEDU29',
      'roll': '12',
      'email': 'ishrakfaisal100@gmail.com',
      'image': 'assets/images/Ishraq.jpg',
    },
    {
      'name': 'Jobaer Hossain Tamim',
      'Batch': 'CSEDU29',
      'roll': '24',
      'email': 'jobaertamim7@gmail.com',
      'image': 'assets/images/Tamim.jpg',
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
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open email for $email')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GAppBar(title: "About Us"),
      backgroundColor: Colors.white, // Set the whole screen background to white
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        children: [
          Center(
            child: Text(
              "Meet Our Team",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...teamMembers.map(
            (member) => Card(
              elevation: 4,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height:130,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(20),
                        ),
                        child: Image.asset(
                          member['image']!,
                          fit: BoxFit.cover,
                          height: double.infinity,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member['name']!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              member['Batch']!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Roll: ${member['roll'] ?? ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () => _launchEmail(context, member['email']!),
                              child: Text(
                                member['email']!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.blueAccent,
                                  decoration: TextDecoration.underline,
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
            ),
          ),
          const SizedBox(height: 40),
          Text(
            "‘Murir Tin’ is a smart local bus app that uniquely combines color-coded routes, live GPS tracking, QR-based easy ticket booking, and a complaint box — making daily transportation smoother and easier while putting control back in the passenger's hands.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.black87,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
