import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class BusStopResponse {
  final String name;
  final double latitude;
  final double longitude;

  BusStopResponse({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory BusStopResponse.fromJson(Map<String, dynamic> json) {
    return BusStopResponse(
      name: json['name'],
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }

  Position get position => Position(longitude, latitude);
}

Future<List<BusStopResponse>> fetchBusStops(String routeId) async {
  const baseUrl = 'http://192.168.0.168:8000';
  final url = Uri.parse('$baseUrl/bus/bus_stop/$routeId');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => BusStopResponse.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      throw Exception('Route not found');
    } else {
      throw Exception('Failed to load bus stops: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching data: $e');
  }
}

class BusMap extends StatefulWidget {
  final String routeId;

  const BusMap({super.key, required this.routeId});

  @override
  State<BusMap> createState() => _BusMapState();
}

class _BusMapState extends State<BusMap> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  List<BusStopResponse> busStops = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBusStops();
  }

  Future<void> _fetchBusStops() async {
    // Check if widget is still mounted before updating state
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final stops = await fetchBusStops(widget.routeId);

      // Check again before updating state
      if (!mounted) return;

      setState(() {
        busStops = stops;
        isLoading = false;
      });

      // Update markers if map is ready
      if (mapboxMap != null) {
        _createAllMarkers();
        if (busStops.isNotEmpty) {
          _zoomToRoute();
        }
      }
    } catch (e) {
      // Check again before showing error
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    pointAnnotationManager?.deleteAll();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapBoxMap) {
    mapboxMap = mapBoxMap;

    mapBoxMap.annotations.createPointAnnotationManager().then((manager) {
      pointAnnotationManager = manager;
      _createAllMarkers();

      if (busStops.isNotEmpty) {
        _zoomToRoute();
      }
    });
  }

  void _createAllMarkers() {
    pointAnnotationManager?.deleteAll();

    for (var stop in busStops) {
      _createMarker(stop);
    }
  }

  void _createMarker(BusStopResponse stop) {
    pointAnnotationManager?.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: stop.position),
        iconImage: "bus",
        iconSize: 2.5,
        iconColor: _generateColor(stop.name).value,
        textField: stop.name,
        textColor: Colors.black.value,
        textSize: 12.0,
        textOffset: [0, 1.5],
        textHaloColor: Colors.white.value,
        textHaloWidth: 1.0,
      ),
    );
  }

  Color _generateColor(String seed) {
    final random = Random(seed.hashCode);
    return Color.fromRGBO(
      random.nextInt(200) + 55,
      random.nextInt(200) + 55,
      random.nextInt(200) + 55,
      1,
    );
  }

  void _zoomToRoute() {
    if (busStops.isEmpty || mapboxMap == null) return;

    // Calculate bounds
    double minLat = busStops.first.latitude;
    double maxLat = busStops.first.latitude;
    double minLng = busStops.first.longitude;
    double maxLng = busStops.first.longitude;

    for (final stop in busStops) {
      if (stop.latitude < minLat) minLat = stop.latitude;
      if (stop.latitude > maxLat) maxLat = stop.latitude;
      if (stop.longitude < minLng) minLng = stop.longitude;
      if (stop.longitude > maxLng) maxLng = stop.longitude;
    }

    // Calculate center
    final center = Point(
      coordinates: Position((minLng + maxLng) / 2, (minLat + maxLat) / 2),
    );

    // Calculate zoom level based on the area
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final zoom = 11.5 - max(latDiff, lngDiff) * 5;

    // Fly to the calculated position
    mapboxMap?.flyTo(
      CameraOptions(
        center: center,
        zoom: zoom.clamp(10.0, 16.0), // Constrain between min/max zoom
        padding: MbxEdgeInsets(top: 100, bottom: 100, left: 50, right: 50),
      ),
      MapAnimationOptions(duration: 2000),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route ${widget.routeId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBusStops,
            tooltip: 'Refresh stops',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            onPressed: _zoomToRoute,
            tooltip: 'Show all stops',
          ),
        ],
      ),
      body: Stack(
        children: [
          MapWidget(
            styleUri: MapboxStyles.DARK,
            onMapCreated: _onMapCreated,
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(90.45041, 23.70287)),
              zoom: 14,
            ),
          ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
          if (errorMessage != null)
            Positioned(top: 20, left: 20, right: 20, child: _buildErrorCard()),
          if (busStops.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildSummaryCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => errorMessage = null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Route ${widget.routeId}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${busStops.length} bus stops',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: busStops
                  .take(3)
                  .map(
                    (stop) => Chip(
                      label: Text(stop.name),
                      backgroundColor: _generateColor(
                        stop.name,
                      ).withValues(alpha: 0.2),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}







