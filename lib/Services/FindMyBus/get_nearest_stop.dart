import 'dart:convert';

import 'package:murir_tin/Models/nearest_stop.dart';
import 'package:http/http.dart';

Future<NearestStop> getNearestStop(
  double latitude,
  double longitude,
  // ignore: non_constant_identifier_names
  String route_id,
) async {
  const baseUrl = 'https://murir-tin-server.vercel.app';
  final url = Uri.parse('$baseUrl/bus/nearest_stop');

  try {
    final response = await post(
      Uri.parse(url.toString()),
      body: json.encode({
        "latitude": latitude,
        "longitude": longitude,
        "route_id": route_id,
      }),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return NearestStop.fromMap(data);
    } else if (response.statusCode == 500) {
      throw Exception('Internal server error. Please try again later.');
    } else {
      throw Exception('Failed to load nearest stop: ${response.statusCode}');
    }
  } catch (e) {
    if (e is Exception) {
      errorHandler(e);
    } else {
      errorHandler(Exception(e.toString()));
    }
    return NearestStop(
      name: '',
      latitude: 0,
      longitude: 0,
      distance: 0,
      duration: 0,
      coordinates: [],
    );
  }
}

void errorHandler(Exception e) {
  if (e is ClientException) {
    throw Exception(
      'Network error. Check your connection and try again later.',
    );
  } else {
    throw Exception(
      'An unexpected error occurred. Contact developer for help. $e',
    );
  }
}