import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class LiveBusTracker extends StatefulWidget {
  const LiveBusTracker({super.key});

  @override
  State<LiveBusTracker> createState() => _LiveBusTrackerState();
}

class _LiveBusTrackerState extends State<LiveBusTracker>
    with SingleTickerProviderStateMixin {
  mapbox.MapboxMap? mapboxMap;
  mapbox.PointAnnotationManager? busAnnotationManager;
  List<mapbox.PointAnnotation>? busAnnotations = [];
  Timer? _busUpdateTimer;
  int currentRouteIndex = 0;
  late AnimationController _pulseController;

  // Hardcoded bus simulation data from server database
  final List<Map<String, dynamic>> busSimulationData = [
    {
      "id": "bus_001",
      "route": "Route 2",
      "driver": "Ahmed Khan",
      "capacity": 40,
      "currentPassengers": 23,
      "coordinates": [
        [90.448742, 23.703315],
        [90.448294, 23.70353],
        [90.448289, 23.70366],
        [90.448113, 23.703741],
        [90.447615, 23.703972],
        [90.446814, 23.704343],
        [90.445905, 23.704756],
        [90.445647, 23.704918],
        [90.444597, 23.705389],
        [90.443451, 23.705802],
        [90.442072, 23.706514],
        [90.441324, 23.706867],
        [90.439814, 23.707621],
        [90.439286, 23.70787],
        [90.438454, 23.708249],
        [90.436896, 23.70901],
        [90.435009, 23.709871],
        [90.43447, 23.710078],
        [90.433658, 23.710302],
        [90.433321, 23.710372],
        [90.432622, 23.710552],
        [90.431491, 23.710901],
        [90.430881, 23.711074],
        [90.4304, 23.711257],
        [90.430174, 23.711367],
        [90.429865, 23.711545],
        [90.428261, 23.71259],
        [90.425799, 23.714291],
        [90.425565, 23.714419],
        [90.425252, 23.714548],
        [90.424995, 23.714616],
        [90.424164, 23.714939],
        [90.423987, 23.715021],
        [90.423759, 23.715142],
        [90.423032, 23.715628],
        [90.422691, 23.715816],
        [90.422533, 23.71588],
        [90.422318, 23.715933],
        [90.421616, 23.716032],
        [90.421412, 23.71608],
        [90.42123, 23.716139],
        [90.420766, 23.716349],
        [90.420655, 23.716439],
        [90.420339, 23.716774],
        [90.419522, 23.718053],
        [90.418602, 23.719746],
        [90.41844, 23.720004],
        [90.418224, 23.720299],
        [90.417994, 23.720588],
        [90.417724, 23.720881],
      ],
    },
    {
      "id": "bus_002",
      "route": "Route 3",
      "driver": "Karim Uddin",
      "capacity": 35,
      "currentPassengers": 18,
      "coordinates": [
        [90.417415, 23.721118],
        [90.41694, 23.721518],
        [90.416347, 23.721907],
        [90.416218, 23.722003],
        [90.415579, 23.722388],
        [90.415064, 23.722621],
        [90.414805, 23.722716],
        [90.414427, 23.722828],
        [90.413945, 23.722915],
        [90.413655, 23.722952],
        [90.413236, 23.722966],
        [90.411842, 23.722921],
        [90.410682, 23.722951],
        [90.408076, 23.723081],
        [90.40681, 23.723126],
        [90.404114, 23.723255],
        [90.403761, 23.723293],
        [90.40293, 23.723449],
        [90.40261, 23.72353],
        [90.402555, 23.723543],
        [90.401668, 23.723705],
        [90.400337, 23.723875],
        [90.400304, 23.723873],
        [90.400288, 23.723879],
        [90.400276, 23.723889],
        [90.400269, 23.723933],
        [90.400289, 23.723957],
        [90.400298, 23.72412],
        [90.400273, 23.724292],
        [90.400157, 23.72459],
        [90.400023, 23.724795],
        [90.39948, 23.725354],
        [90.398694, 23.726185],
        [90.398257, 23.726695],
        [90.397727, 23.727276],
        [90.397627, 23.727368],
        [90.397403, 23.72759],
        [90.397291, 23.727701],
        [90.396752, 23.728237],
        [90.39672, 23.728268],
      ],
    },
  ];

  Map<String, int> busPositionIndices = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Initialize bus position indices
    for (var bus in busSimulationData) {
      busPositionIndices[bus['id']] = 0;
    }

    _startBusSimulation();
  }

  @override
  void dispose() {
    _busUpdateTimer?.cancel();
    _pulseController.dispose();
    busAnnotationManager?.deleteAll();
    super.dispose();
  }

  void _startBusSimulation() {
    _busUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateBusPositions();
    });
  }

  void _updateBusPositions() async {
    if (!mounted || busAnnotationManager == null) {
      print(
        'Cannot update positions: mounted=$mounted, manager=${busAnnotationManager != null}',
      );
      return;
    }

    // Clear existing bus annotations
    await busAnnotationManager?.deleteAll();
    busAnnotations?.clear();

    print('Updating positions for ${busSimulationData.length} buses');

    for (var bus in busSimulationData) {
      String busId = bus['id'];
      List coordinates = bus['coordinates'];
      int currentIndex = busPositionIndices[busId] ?? 0;

      if (currentIndex < coordinates.length) {
        var currentCoord = coordinates[currentIndex];
        print(
          'Creating marker for $busId at ${currentCoord[1]}, ${currentCoord[0]}',
        );
        _createBusMarker(bus, currentCoord[0], currentCoord[1]);

        // Move to next position
        busPositionIndices[busId] = (currentIndex + 1) % coordinates.length;
      }
    }
  }

  void _createBusMarker(
    Map<String, dynamic> bus,
    double longitude,
    double latitude,
  ) {
    if (busAnnotationManager == null) {
      print('Cannot create marker: annotation manager is null');
      return;
    }

    print('Creating marker for ${bus['id']} at $latitude, $longitude');

    busAnnotationManager
        ?.create(
          mapbox.PointAnnotationOptions(
            geometry: mapbox.Point(
              coordinates: mapbox.Position(longitude, latitude),
            ),
            iconImage: "bus",
            iconSize: 1.5,
            iconAnchor: mapbox.IconAnchor.BOTTOM,
            iconColor: const Color.fromARGB(255, 255, 0, 0).toARGB32(),
            textField: bus['route'],
            textSize: 8.0,
          ),
        )
        .then((annotation) {
          if (mounted) {
            print('Marker created successfully for ${bus['id']}');
            setState(() {
              busAnnotations?.add(annotation);
            });
          }
        })
        .catchError((error) {
          print('Error creating marker for ${bus['id']}: $error');
        });
  }

  void _onMapCreated(mapbox.MapboxMap mapBoxMap) async {
    mapboxMap = mapBoxMap;

    // Set initial camera position to show the bus area
    await mapBoxMap.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(
            90.42,
            23.715,
          ), // Centered between bus locations
        ),
        zoom: 14.0, // Higher zoom to see markers better
      ),
      mapbox.MapAnimationOptions(duration: 1000),
    );

    // Wait a bit for map to be ready, then create annotation manager
    await Future.delayed(const Duration(milliseconds: 500));

    // Create bus annotation manager
    try {
      busAnnotationManager =
          await mapboxMap?.annotations.createPointAnnotationManager();
      print('Bus annotation manager created successfully');

      // Initial position update after manager is ready
      _updateBusPositions();
    } catch (e) {
      print('Error creating annotation manager: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF14213D),
        foregroundColor: Colors.white,
        title: Text(
          'Live Bus Tracker',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Restart Simulation',
              onPressed: () {
                // Reset positions
                for (var bus in busSimulationData) {
                  busPositionIndices[bus['id']] = 0;
                }
                _updateBusPositions();
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
              tooltip: 'Bus Information',
              onPressed: () {
                _showBusInfoBottomSheet();
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          mapbox.MapWidget(
            styleUri: mapbox.MapboxStyles.LIGHT,
            onMapCreated: _onMapCreated,
          ),

          // Live indicator
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF14213D),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(
                            0.3 + (0.7 * _pulseController.value),
                          ),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bus count indicator
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00C851),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_bus_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${busSimulationData.length} Active',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF14213D),
        foregroundColor: Colors.white,
        onPressed: () {
          print('Centering camera on bus area...');
          // Center camera on bus area
          mapboxMap?.flyTo(
            mapbox.CameraOptions(
              center: mapbox.Point(coordinates: mapbox.Position(90.42, 23.715)),
              zoom: 14.0,
            ),
            mapbox.MapAnimationOptions(duration: 1000),
          );

          // Also refresh markers
          _updateBusPositions();
        },
        child: const Icon(Icons.my_location_rounded),
      ),
    );
  }

  void _showBusInfoBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF14213D), Color(0xFF2A3F5F)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.directions_bus_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Active Buses',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bus list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: busSimulationData.length,
                    itemBuilder: (context, index) {
                      var bus = busSimulationData[index];
                      int currentPos = busPositionIndices[bus['id']] ?? 0;
                      int totalStops = bus['coordinates'].length;
                      double progress = currentPos / totalStops;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF00C851,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.directions_bus_rounded,
                                    color: Color(0xFF00C851),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bus['route'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF14213D),
                                        ),
                                      ),
                                      Text(
                                        'Driver: ${bus['driver']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00C851),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'LIVE',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Progress bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Route Progress',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      '${(progress * 100).toInt()}%',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF14213D),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[300],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF00C851),
                                      ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Passenger info
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoTile(
                                    'Passengers',
                                    '${bus['currentPassengers']}/${bus['capacity']}',
                                    Icons.people_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInfoTile(
                                    'Next Stop',
                                    '${currentPos + 1}/$totalStops',
                                    Icons.location_on_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF14213D), size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF14213D),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
