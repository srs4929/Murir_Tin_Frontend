import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:murir_tin/Component.dart';
import 'package:murir_tin/api.dart';
import 'package:murir_tin/StatusScreen.dart';

class ComplaintStatusScreen extends StatefulWidget {
  final String? username;
  final String? email;
  final String? profilePicUrl;

  const ComplaintStatusScreen({
    super.key,
    this.username,
    this.email,
    this.profilePicUrl,
  });

  @override
  State<ComplaintStatusScreen> createState() => _ComplaintStatusScreenState();
}

class _ComplaintStatusScreenState extends State<ComplaintStatusScreen> {
  final _storage = FlutterSecureStorage();
  bool _isLoading = true;
  List<Map<String, String>> complaints = [];

  @override
  void initState() {
    super.initState();
    _fetchUserComplaints();
  }

  Future<void> _fetchUserComplaints() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception("Token not found");

      final response = await http.get(
        Uri.parse(complaint_status_endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          complaints =
              data.map<Map<String, String>>((item) {
                final createdAt = DateTime.parse(item['created_at']);
                return {
                  'id': item['id'].toString(),
                  'title': item['title'],
                  'date':
                      "${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}",
                  'time':
                      "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')} ${createdAt.hour < 12 ? 'AM' : 'PM'}",
                };
              }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load complaints');
      }
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final middleBlueColor = Color(0xFF2F4F78);

    return Scaffold(
      appBar: GAppBar(title: "Complain Status"),

      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: middleBlueColor))
              : complaints.isEmpty
              ? Center(child: Text("No complaints submitted yet."))
              : ListView.builder(
                itemCount: complaints.length,
                itemBuilder: (context, index) {
                  final complaint = complaints[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  complaint['title']!,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      complaint['date']!,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      complaint['time']!,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  final complaintId = int.parse(
                                    complaint['id']!,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => StatusScreen(
                                            complaintId: complaintId,
                                          ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: middleBlueColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 24,
                                  ),
                                ),
                                child: Text(
                                  "View Current Status & Details",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
