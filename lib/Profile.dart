import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:murir_tin/api.dart';
import 'EditProfile.dart';

class MyProfileScreen extends StatefulWidget {
  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final storage = FlutterSecureStorage();

  String username = "";
  String email = "";
  String phoneNumber = "";
  String profilePicUrl = "https://www.w3schools.com/w3images/avatar2.png";
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      final token = await storage.read(key: 'jwt_token');
      if (token == null) {
        setState(() {
          errorMessage = "Token not found.";
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(user_info),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          username = data['username'] ?? '';
          email = data['email'] ?? '';
          phoneNumber = data['phone'] ?? '';
          profilePicUrl = data['profile_pic_url'] ?? profilePicUrl;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load profile: ${response.reasonPhrase}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "An error occurred: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final middleBlueColor = Color(0xFF2F4F78);
    final darkBlueColor = Color(0xFF14213D);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [middleBlueColor, darkBlueColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 30),
          onPressed: () {},
        ),
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            CircleAvatar(
              radius: 100,
              backgroundImage: NetworkImage(profilePicUrl),
            ),
            const SizedBox(height: 16),
            Text(
              username.isEmpty ? 'N/A' : username,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: middleBlueColor),
            ),
            const SizedBox(height: 16),

            _buildInfoBox("Email", email, darkBlueColor),
            _buildInfoBox("Phone Number", phoneNumber, darkBlueColor),

            ElevatedButton(
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      username: username,
                      email: email,
                      phone: phoneNumber,
                    ),
                  ),
                );

                if (updated == true) {
                  fetchUserProfile(); // Refresh after edit
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(150, 50),
                backgroundColor: middleBlueColor,
              ),
              child: Text('Edit Profile',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, Color labelColor) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(label,
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: labelColor)),
          Spacer(),
          Text(value.isEmpty ? 'N/A' : value,
              style: TextStyle(fontSize: 16, color: Colors.black)),
        ],
      ),
    );
  }
}