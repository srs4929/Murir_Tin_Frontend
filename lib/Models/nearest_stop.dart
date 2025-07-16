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
      name: (mapData['name'] ?? '').toString().trim(),
      latitude: (mapData['latitude'] ?? 0.0).toDouble(),
      longitude: (mapData['longitude'] ?? 0.0).toDouble(),
      distance: (mapData['distance'] ?? 0.0).toDouble(),
      duration: (mapData['duration'] ?? 0.0).toDouble(),
      coordinates:
          mapData['coordinates'] != null
              ? List<List<double>>.from(
                (mapData['coordinates'] as List).map(
                  (e) => List<double>.from(e.map((x) => (x ?? 0.0).toDouble())),
                ),
              )
              : [],
    );
  }
}
