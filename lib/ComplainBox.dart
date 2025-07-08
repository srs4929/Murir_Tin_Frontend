import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api.dart';

class ComplaintBoxScreen extends StatefulWidget {
  final String? username;
  final String? email;
  final String? profilePicUrl;

  const ComplaintBoxScreen({
    Key? key,
    this.username,
    this.email,
    this.profilePicUrl,
  }) : super(key: key);

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
      print("Error loading companies: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bus companies')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchBusCompanies(String jwtToken) async {
    final response = await http.get(
      Uri.parse(complaints_companies_endpoint),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data
          .map<Map<String, dynamic>>((item) => {
        'id': item['id'],
        'name': item['name'],
      })
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
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to submit complaint');
    }
  }

  @override
  Widget build(BuildContext context) {
    final middleBlueColor = Color(0xFF2F4F78);
    final selectedTextColor = Colors.black;

    List<Map<String, dynamic>> sortedBusCompanies = List.from(busCompanies)
      ..sort((a, b) => a['name'].compareTo(b['name']));

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                middleBlueColor,
                Color(0xFF14213D),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: const Text(
          'Complaint Box',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: widget.profilePicUrl != null &&
                widget.profilePicUrl!.isNotEmpty
                ? CircleAvatar(
              backgroundImage: NetworkImage(widget.profilePicUrl!),
              backgroundColor: Colors.white,
            )
                : const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.black),
            ),
            onPressed: () {
              // Optional: handle profile tap
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Company",
              style: TextStyle(fontSize: 20, color: middleBlueColor),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSearching = true;
                });
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: middleBlueColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCompany ?? 'Select Bus Company',
                      style: TextStyle(
                        color: _selectedCompany == null
                            ? Colors.grey[600]
                            : selectedTextColor,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            if (_isSearching)
              Container(
                padding: const EdgeInsets.only(top: 8),
                child: SingleChildScrollView(
                  child: Column(
                    children: sortedBusCompanies.map((company) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCompany = company['name'];
                            _isSearching = false;
                          });
                        },
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: _selectedCompany == company['name']
                                  ? Colors.blue[300]
                                  : Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: middleBlueColor),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            child: Text(
                              company['name'],
                              style: TextStyle(
                                fontSize: 18,
                                color: _selectedCompany == company['name']
                                    ? selectedTextColor
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              "Title",
              style: TextStyle(fontSize: 20, color: middleBlueColor),
            ),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Give title of your complaint',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: middleBlueColor),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Description",
              style: TextStyle(fontSize: 20, color: middleBlueColor),
            ),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Give details about your complaint',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: middleBlueColor),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _isSubmitted
                    ? null
                    : () async {
                  if (_selectedCompany == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Please select a company')),
                    );
                    return;
                  }

                  try {
                    final jwtToken = await _secureStorage.read(
                        key: 'jwt_token');
                    if (jwtToken == null) {
                      throw Exception('JWT token not found');
                    }

                    final company = busCompanies.firstWhere(
                            (c) => c['name'] == _selectedCompany);
                    final companyId = company['id'].toString();

                    await submitComplaint(
                      jwtToken: jwtToken,
                      title: _titleController.text,
                      description: _descriptionController.text,
                      companyId: companyId,
                    );

                    setState(() {
                      _isSubmitted = true;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Complaint Submitted')),
                    );
                  } catch (e) {
                    print("Error submitting complaint: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Failed to submit complaint')),
                    );
                  }
                },
                child: Text(
                  _isSubmitted ? "Submitted" : "Submit",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: middleBlueColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}