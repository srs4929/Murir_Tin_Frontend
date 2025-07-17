import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:murir_tin/Component.dart';
import 'package:murir_tin/TicketSelectionScreen.dart';

import 'api.dart';

class ComplaintBoxScreen extends StatefulWidget {
  final String? username;
  final String? email;
  final String? profilePicUrl;

  const ComplaintBoxScreen({
    super.key,
    this.username,
    this.email,
    this.profilePicUrl,
  });

  @override
  _ComplaintBoxScreenState createState() => _ComplaintBoxScreenState();
}

class _ComplaintBoxScreenState extends State<ComplaintBoxScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _secureStorage = FlutterSecureStorage();

  bool _isSubmitted = false;
  String? _selectedCompany;
  bool _isSearching = false;
  String? _selectedTicketId;
  Map<String, dynamic>? _selectedTicketData;

  List<Map<String, dynamic>> busCompanies = [];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final jwtToken = await _secureStorage.read(key: 'jwt_token');
      if (jwtToken == null) {
        throw Exception('JWT token not found');
      }

      final companies = await fetchBusCompanies(jwtToken);
      setState(() {
        busCompanies = companies;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load bus companies')));
    }
  }

  Future<List<Map<String, dynamic>>> fetchBusCompanies(String jwtToken) async {
    final response = await http.get(
      Uri.parse(complaints_companies_endpoint),
      headers: {'Authorization': 'Bearer $jwtToken'},
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data
          .map<Map<String, dynamic>>(
            (item) => {'id': item['id'], 'name': item['name']},
          )
          .toList();
    } else {
      throw Exception('Failed to load companies');
    }
  }

  Future<void> submitComplaint({
    required String jwtToken,
    required String title,
    required String description,
    required String companyId,
    required String ticketId,
  }) async {
    final response = await http.post(
      Uri.parse(complaints_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: json.encode({
        'title': title,
        'description': description,
        'company_id': companyId,
        'ticket_id': ticketId,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to submit complaint');
    }
  }

  @override
  Widget build(BuildContext context) {
    final middleBlueColor = Color(0xFF4B6EAF);
    final darkBlueColor = Color(0xFF14213D);

    List<Map<String, dynamic>> sortedBusCompanies = List.from(busCompanies)
      ..sort((a, b) => a['name'].compareTo(b['name']));

    return Scaffold(
      appBar: GAppBar(title: "Complaint Box"),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.blue.shade50.withOpacity(0.1)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [darkBlueColor, middleBlueColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: middleBlueColor.withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.feedback_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Submit Your Complaint',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Help us improve our service by sharing your feedback',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // Company Selection Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: middleBlueColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.business_rounded,
                            color: middleBlueColor,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Select Bus Company",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: darkBlueColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSearching = !_isSearching;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey.shade50, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color:
                                _selectedCompany != null
                                    ? middleBlueColor.withOpacity(0.3)
                                    : Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade100,
                              spreadRadius: 0,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedCompany ?? 'Choose your bus company',
                                style: GoogleFonts.poppins(
                                  color:
                                      _selectedCompany == null
                                          ? Colors.grey.shade600
                                          : darkBlueColor,
                                  fontSize: 15,
                                  fontWeight:
                                      _selectedCompany == null
                                          ? FontWeight.w500
                                          : FontWeight.w600,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: _isSearching ? 0.5 : 0,
                              duration: Duration(milliseconds: 300),
                              child: Icon(
                                Icons.expand_more_rounded,
                                color: middleBlueColor,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Company Options Dropdown
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: _isSearching ? null : 0,
                      child:
                          _isSearching
                              ? Container(
                                margin: EdgeInsets.only(top: 12),
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: middleBlueColor.withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade200,
                                      spreadRadius: 0,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children:
                                      sortedBusCompanies.map((company) {
                                        bool isSelected =
                                            _selectedCompany == company['name'];
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedCompany =
                                                  company['name'];
                                              _isSearching = false;
                                            });
                                          },
                                          child: Container(
                                            margin: EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical: 14,
                                              horizontal: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient:
                                                  isSelected
                                                      ? LinearGradient(
                                                        colors: [
                                                          middleBlueColor
                                                              .withOpacity(0.1),
                                                          middleBlueColor
                                                              .withOpacity(
                                                                0.05,
                                                              ),
                                                        ],
                                                      )
                                                      : LinearGradient(
                                                        colors: [
                                                          Colors.grey.shade50,
                                                          Colors.white,
                                                        ],
                                                      ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color:
                                                    isSelected
                                                        ? middleBlueColor
                                                            .withOpacity(0.3)
                                                        : Colors.grey.shade200,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isSelected
                                                            ? middleBlueColor
                                                            : Colors
                                                                .grey
                                                                .shade300,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    isSelected
                                                        ? Icons.check_rounded
                                                        : Icons
                                                            .business_rounded,
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    company['name'],
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          isSelected
                                                              ? FontWeight.w600
                                                              : FontWeight.w500,
                                                      color:
                                                          isSelected
                                                              ? middleBlueColor
                                                              : darkBlueColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              )
                              : SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Ticket Selection Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: middleBlueColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.directions_bus,
                            color: middleBlueColor,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Select Ticket",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: darkBlueColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => TicketSelectionScreen(
                                  username: widget.username ?? 'Unknown',
                                ),
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            _selectedTicketId = result['ticketId'];
                            _selectedTicketData = result['ticketData'];
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey.shade50, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color:
                                _selectedTicketId != null
                                    ? middleBlueColor.withOpacity(0.3)
                                    : Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade100,
                              spreadRadius: 0,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedTicketId != null
                                        ? 'Ticket ID: $_selectedTicketId'
                                        : 'Choose the ticket you want to complain about',
                                    style: GoogleFonts.poppins(
                                      color:
                                          _selectedTicketId == null
                                              ? Colors.grey.shade600
                                              : darkBlueColor,
                                      fontSize: 15,
                                      fontWeight:
                                          _selectedTicketId == null
                                              ? FontWeight.w500
                                              : FontWeight.w600,
                                    ),
                                  ),
                                  if (_selectedTicketData != null) ...[
                                    SizedBox(height: 4),
                                    Text(
                                      '${_selectedTicketData!['from_location']} → ${_selectedTicketData!['to_location']}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              _selectedTicketId != null
                                  ? Icons.check_circle_rounded
                                  : Icons.arrow_forward_ios_rounded,
                              color:
                                  _selectedTicketId != null
                                      ? middleBlueColor
                                      : Colors.grey.shade400,
                              size: _selectedTicketId != null ? 24 : 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Title Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: middleBlueColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.title_rounded,
                            color: middleBlueColor,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Complaint Title",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: darkBlueColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade50, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _titleController,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: darkBlueColor,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter a brief title for your complaint',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          prefixIcon: Container(
                            margin: EdgeInsets.all(12),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: middleBlueColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              color: middleBlueColor,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Description Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: middleBlueColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.description_rounded,
                            color: middleBlueColor,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Detailed Description",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: darkBlueColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade50, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 6,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: darkBlueColor,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Provide detailed information about your complaint...',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Submit Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          _isSubmitted
                              ? Colors.green.withOpacity(0.3)
                              : middleBlueColor.withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed:
                      _isSubmitted
                          ? null
                          : () async {
                            if (_selectedCompany == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Please select a bus company'),
                                    ],
                                  ),
                                  backgroundColor: Colors.orange.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                              return;
                            }

                            if (_selectedTicketId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Please select a ticket to complain against',
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.orange.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                              return;
                            }

                            if (_titleController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Please enter a complaint title'),
                                    ],
                                  ),
                                  backgroundColor: Colors.orange.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                              return;
                            }

                            if (_descriptionController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Please provide a detailed description',
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.orange.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                              return;
                            }

                            try {
                              final jwtToken = await _secureStorage.read(
                                key: 'jwt_token',
                              );
                              if (jwtToken == null) {
                                throw Exception('JWT token not found');
                              }

                              final company = busCompanies.firstWhere(
                                (c) => c['name'] == _selectedCompany,
                              );
                              final companyId = company['id'].toString();

                              await submitComplaint(
                                jwtToken: jwtToken,
                                title: _titleController.text.trim(),
                                description: _descriptionController.text.trim(),
                                companyId: companyId,
                                ticketId: _selectedTicketId!,
                              );

                              setState(() {
                                _isSubmitted = true;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Complaint submitted successfully!',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            } catch (e) {
                              print("Error submitting complaint: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.error_rounded,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Failed to submit complaint. Please try again.',
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isSubmitted ? Colors.green.shade600 : middleBlueColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSubmitted)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 24,
                          color: Colors.white,
                        )
                      else
                        Icon(Icons.send_rounded, size: 22, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        _isSubmitted
                            ? "Complaint Submitted"
                            : "Submit Complaint",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Success Message Card
              if (_isSubmitted)
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade50,
                        Colors.green.shade100.withOpacity(0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.celebration_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thank You!',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Your complaint has been received and will be reviewed by our team. We\'ll keep you updated on the progress.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
