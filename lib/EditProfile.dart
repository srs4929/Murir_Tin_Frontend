import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:murir_tin/Component.dart';
import 'package:murir_tin/api.dart';
import 'package:path/path.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EditProfileScreen extends StatefulWidget {
  final String username;
  final String email;
  final String phone;
  final String? imagePath;

  EditProfileScreen({
    required this.username,
    required this.email,
    required this.phone,
    this.imagePath,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final storage = FlutterSecureStorage();
  final picker = ImagePicker();

  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  File? _pickedImageFile;
  String? _uploadedImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
    _uploadedImageUrl = widget.imagePath;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _pickedImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile(BuildContext context) async {
    setState(() {
      _isUploading = true;
    });

    final token = await storage.read(key: 'jwt_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication token not found.')),
      );
      setState(() {
        _isUploading = false;
      });
      return;
    }

    final uri = Uri.parse(update_profile);
    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['username'] = _usernameController.text.trim();
    request.fields['email'] = _emailController.text.trim();

    if (_pickedImageFile != null) {
      final fileStream = http.ByteStream(_pickedImageFile!.openRead());
      final fileLength = await _pickedImageFile!.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: basename(_pickedImageFile!.path),
      );
      request.files.add(multipartFile);
    }

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final responseData = json.decode(respStr);

        // Handle the nested response structure
        String? newImageUrl;
        if (responseData['data'] != null) {
          if (responseData['data'] is List && responseData['data'].isNotEmpty) {
            newImageUrl = responseData['data'][0]['profile_pic_url'];
          } else if (responseData['data'] is Map) {
            newImageUrl = responseData['data']['profile_pic_url'];
          }
        }

        // Fallback to direct access if needed
        newImageUrl ??= responseData['profile_pic_url'];

        if (newImageUrl != null) {
          setState(() {
            _uploadedImageUrl = newImageUrl;
            _pickedImageFile = null; // Clear the picked file
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        final respStr = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $respStr')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }

    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final middleBlueColor = Color(0xFF2F4F78);

    return Scaffold(
      appBar: GAppBar(title: "Edit Profile"),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 100,
                backgroundImage: _pickedImageFile != null
                    ? FileImage(_pickedImageFile!)
                    : (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty
                    ? NetworkImage(_uploadedImageUrl!)
                    : null),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: _pickImage,
              child: Text(
                'Change Picture',
                style: TextStyle(
                  fontSize: 24,
                  color: middleBlueColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildTextField("Username", _usernameController, middleBlueColor),
            SizedBox(height: 16),
            _buildTextField("Email", _emailController, middleBlueColor),
            SizedBox(height: 16),
            _buildTextField("Phone Number", _phoneController, middleBlueColor),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isUploading ? null : () => _saveProfile(context),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(150, 50),
                backgroundColor: middleBlueColor,
              ),
              child: _isUploading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Update', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 20, color: color)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          cursorColor: color,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: color),
            ),
          ),
        ),
      ],
    );
  }
}