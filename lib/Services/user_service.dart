import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:murir_tin/api.dart';
import 'package:murir_tin/Models/user_model.dart';

class UserService {
  static const _storage = FlutterSecureStorage();

  // Get JWT token from secure storage
  static Future<String?> _getJwtToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Get user info (detailed profile)
  static Future<UserModel?> getUserInfo() async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse(user_info),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: getUserInfo response status: ${response.statusCode}');
      print('DEBUG: getUserInfo response body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        // Add ID from token if not present in response
        if (!userData.containsKey('id')) {
          userData['id'] = await _getUserIdFromToken(token);
        }
        return UserModel.fromJson(userData);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to fetch user info: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: getUserInfo - $e');
      rethrow;
    }
  }

  // Get user profile (basic landing data)
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse(landing_page_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: getUserProfile response status: ${response.statusCode}');
      print('DEBUG: getUserProfile response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to fetch user profile: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: getUserProfile - $e');
      rethrow;
    }
  }

  // Update user profile
  static Future<UserModel?> updateUserProfile({
    String? username,
    String? email,
    String? phone,
    String? profilePicUrl,
  }) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Create multipart request since server expects Form data
      final request = http.MultipartRequest('PUT', Uri.parse(update_profile));

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      if (username != null) request.fields['username'] = username;
      if (email != null) request.fields['email'] = email;
      // Note: Server might not support phone field, but we'll try

      print('DEBUG: updateUserProfile fields: ${request.fields}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('DEBUG: updateUserProfile response status: ${response.statusCode}');
      print('DEBUG: updateUserProfile response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('DEBUG: Server response data: $responseData');

        // The server returns: {"message": "...", "data": {...}}
        if (responseData['data'] != null) {
          return UserModel.fromJson(responseData['data']);
        } else {
          // If no data field, try to parse the response directly
          return UserModel.fromJson(responseData);
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        final errorMessage =
            response.body.isNotEmpty ? response.body : 'Unknown error';
        throw Exception(
          'Failed to update profile: ${response.statusCode} - $errorMessage',
        );
      }
    } catch (e) {
      print('ERROR: updateUserProfile - $e');
      rethrow;
    }
  }

  // Update user profile with image upload
  static Future<UserModel?> updateUserProfileWithImage({
    String? username,
    String? email,
    String? imagePath,
  }) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Create multipart request for file upload
      final request = http.MultipartRequest('PUT', Uri.parse(update_profile));

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      if (username != null) request.fields['username'] = username;
      if (email != null) request.fields['email'] = email;

      // Add image file if provided
      if (imagePath != null) {
        final file = File(imagePath);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath('file', imagePath),
          );
        }
      }

      print('DEBUG: updateUserProfileWithImage fields: ${request.fields}');
      print(
        'DEBUG: updateUserProfileWithImage files: ${request.files.map((f) => f.field)}',
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
        'DEBUG: updateUserProfileWithImage response status: ${response.statusCode}',
      );
      print(
        'DEBUG: updateUserProfileWithImage response body: ${response.body}',
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('DEBUG: Server response data: $responseData');

        // The server returns: {"message": "...", "data": {...}}
        if (responseData['data'] != null) {
          return UserModel.fromJson(responseData['data']);
        } else {
          // If no data field, try to parse the response directly
          return UserModel.fromJson(responseData);
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        final errorMessage =
            response.body.isNotEmpty ? response.body : 'Unknown error';
        throw Exception(
          'Failed to update profile: ${response.statusCode} - $errorMessage',
        );
      }
    } catch (e) {
      print('ERROR: updateUserProfileWithImage - $e');
      rethrow;
    }
  }

  // Helper method to extract user ID from JWT token
  static Future<String> _getUserIdFromToken(String token) async {
    try {
      // Simple JWT decode (for the sub claim)
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token format');
      }

      final payload = parts[1];
      // Proper base64 padding handling
      String normalized = payload;

      // Remove any existing padding
      normalized = normalized.replaceAll('=', '');

      // Add correct padding
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }

      final decoded = utf8.decode(base64Url.decode(normalized));
      final data = json.decode(decoded);

      return data['sub']?.toString() ?? '';
    } catch (e) {
      print('ERROR: _getUserIdFromToken - $e');
      return '';
    }
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await _getJwtToken();
    return token != null && token.isNotEmpty;
  }

  // Logout user
  static Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  // Save JWT token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }
}
