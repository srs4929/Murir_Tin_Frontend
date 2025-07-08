import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<String>> getAllRoutes() async {
  const baseUrl = 'https://murir-tin-server.vercel.app';
  final url = Uri.parse('$baseUrl/bus/routes');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => json.toString()).toList();
    } else if (response.statusCode == 500) {
      throw Exception('Internal server error. Please try again later.');
    } else {
      throw Exception('Failed to load routes: ${response.statusCode}');
    }
  } catch (e) {
    if (e is Exception) {
      errorHandler(e);
    } else {
      errorHandler(Exception(e.toString()));
    }
    return [];
  }
}

void errorHandler(Exception e) {
  if (e is http.ClientException) {
    throw Exception(
      'Network error. Check your connection and try again later.',
    );
  } else {
    throw Exception(
      'An unexpected error occurred. Contact developer for help. $e',
    );
  }
}