import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class BusStop {
  final String name;
  final double latitude;
  final double longitude;

  BusStop({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory BusStop.fromMap(Map<String, dynamic> mapData) {
    return BusStop(
      name: mapData['name'].trim(),
      latitude: mapData['latitude'].toDouble() ?? 0.0,
      longitude: mapData['longitude']?.toDouble() ?? 0.0,
    );
  }

  Position get position => Position(longitude, latitude);
}
