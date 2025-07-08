class NearestStop {
  final String name;
  final double latitude;
  final double longitude;
  final double distance;
  final double duration;
  final List<List<double>> coordinates;

  NearestStop({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.duration,
    required this.coordinates,
  });

  factory NearestStop.fromMap(Map<String, dynamic> mapData) {
    return NearestStop(
      name: mapData['name'].trim(),
      latitude: mapData['latitude'].toDouble(),
      longitude: mapData['longitude'].toDouble(),
      distance: mapData['distance'].toDouble(),
      duration: mapData['duration'].toDouble(),
      coordinates: List<List<double>>.from(
        (mapData['coordinates'] as List).map(
          (e) => List<double>.from(e.map((x) => x.toDouble())),
        ),
      ),
    );
  }
}
