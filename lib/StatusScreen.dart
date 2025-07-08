import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StatusScreen extends StatefulWidget {
  final int complaintId;

  const StatusScreen({Key? key, required this.complaintId}) : super(key: key);

  @override
  _StatusScreenState createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final _secureStorage = FlutterSecureStorage();

  bool isSubmitted = false;
  bool isAccepted = false;
  bool isSolved = false;
  String description = '';
  bool isLoading = true;

  final middleBlueColor = Color(0xFF2F4F78);

  @override
  void initState() {
    super.initState();
    fetchComplaintDetails();
  }

  Future<void> fetchComplaintDetails() async {
    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      if (token == null) {
        throw Exception("JWT token not found");
      }

      final response = await http.get(
        Uri.parse('http://192.168.0.106:8000/complaint/${widget.complaintId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          description = data['description'];
          final status = data['status'];
          isSubmitted = status == 'submitted' || status == 'accepted' || status == 'solved';
          isAccepted = status == 'accepted' || status == 'solved';
          isSolved = status == 'solved';
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch complaint');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        description = 'Unable to load complaint details.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionLineColor = Colors.grey;
    final greenColor = Colors.green;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [middleBlueColor, Color(0xFF14213D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: const Text(
          'Current Status',
          style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.black),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildStatusItem('Submitted', isSubmitted, middleBlueColor),
                buildConnectionLine(isSubmitted, isAccepted, connectionLineColor, greenColor),
                buildStatusItem('Accepted', isAccepted, middleBlueColor),
                buildConnectionLine(isAccepted, isSolved, connectionLineColor, greenColor),
                buildStatusItem('Solved', isSolved, middleBlueColor),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Complaint Details:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: middleBlueColor),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: middleBlueColor),
              ),
              child: Text(description, style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: middleBlueColor,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: Text("Back", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatusItem(String status, bool isCompleted, Color color) {
    return Column(
      children: [
        Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? Colors.green : Colors.grey,
          size: 30,
        ),
        SizedBox(height: 8),
        Text(
          status,
          style: TextStyle(
            color: isCompleted ? Colors.green : Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildConnectionLine(
      bool first, bool second, Color lineColor, Color greenColor) {
    return Expanded(
      child: Container(
        height: 2,
        color: first && second ? greenColor : lineColor,
      ),
    );
  }
}