import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/Models/bus_stop.dart';
import 'package:murir_tin/Models/nearest_stop.dart';
import 'package:murir_tin/Services/FindMyBus/get_all_bus_stops.dart';
import 'package:murir_tin/Services/FindMyBus/get_all_routes.dart';
import 'package:murir_tin/Services/FindMyBus/get_nearest_stop.dart';
import 'package:murir_tin/Services/location_handler.dart';
import 'package:murir_tin/api.dart';
import 'package:murir_tin/utils/beautiful_alerts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:murir_tin/Services/FindMyBus/stoppage_url_maker.dart';

class BusMap extends StatefulWidget {
  const BusMap({super.key});

  @override
  State<BusMap> createState() => _BusMapState();
}

class _BusMapState extends State<BusMap> {
  mapbox.MapboxMap? mapboxMap;

  mapbox.PointAnnotationManager? pointAnnotationManager;
  List<mapbox.PointAnnotation>? pointAnnotations = [];
  Position? userLocation;
  String routeId = "2";
  List<String> routes = [];
  bool myLocationClicked = false;
  FlutterSecureStorage storage = const FlutterSecureStorage();
  String? token;

  List<BusStop> busStopLocations = [];

  bool isLoading = true;
  bool isMapReady = false;
  bool isDrawerOpen = false;
  dynamic errorMessage;

  @override
  void dispose() {
    pointAnnotationManager?.deleteAll();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeToken();
    _fetchBusStops();
    _fetchRoutes();
  }

  Future<void> _initializeToken() async {
    try {
      String? storedToken = await storage.read(key: 'jwt_token');
      token = storedToken ?? '';
    } catch (e) {
      token = '';
    }
  }

  Future<void> _fetchUserLocation(BuildContext context) async {
    if (!mounted) return;

    try {
      Position? position = await getCurrentLocation(context);
      _addUserMarker(
        mapbox.Point(
          coordinates: mapbox.Position(
            position?.longitude ?? 0.0,
            position?.latitude ?? 0.0,
          ),
        ),
      );
      if (position != null) {
        userLocation = position;
        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Unable to fetch user location';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
      return;
    }
  }

  Future<void> _fetchNearestStop(BuildContext context) async {
    if (userLocation == null) {
      await _fetchUserLocation(context);
    }

    // Check if userLocation and token are still null after fetching
    if (userLocation == null || token == null || token!.isEmpty) {
      setState(() {
        errorMessage = 'Unable to fetch location or authentication token';
      });
      return;
    }

    try {
      NearestStop? nearestStop = await getNearestStop(
        userLocation!.latitude,
        userLocation!.longitude,
        routeId,
        token!,
      );

      _drawNearestRoute(nearestStop);
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch nearest stop: ${e.toString()}';
      });
    }
  }

  void _drawNearestRoute(NearestStop nearestStop) async {
    if (!mounted) return;

    var coordinates = nearestStop.coordinates;
    await mapboxMap?.style.addSource(
      mapbox.GeoJsonSource(
        id: 'nearest_route',
        data: json.encode({
          "type": "Feature",
          "geometry": {"type": "LineString", "coordinates": coordinates},
        }),
      ),
    );

    await mapboxMap?.style.addLayer(
      mapbox.LineLayer(
        id: 'nearest_route_layer',
        sourceId: 'nearest_route',
        lineJoin: mapbox.LineJoin.ROUND,
        lineCap: mapbox.LineCap.ROUND,
        lineDasharray: [1, 1.5],
        lineColor: const Color.fromARGB(255, 108, 108, 155).toARGB32(),
        lineWidth: 3.0,
        slot: "bottom",
      ),
    );
  }

  Future<void> _fetchRoutes() async {
    if (!mounted) {
      return;
    }
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Ensure token is initialized
      if (token == null || token!.isEmpty) {
        await _initializeToken();
      }

      if (token == null || token!.isEmpty) {
        throw Exception('Authentication token not found');
      }

      List<String> busRoutes = await getAllRoutes(token!);
      setState(() {
        routes = busRoutes;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _drawRouteAndStops() async {
    String url = stoppageUrlMaker(busStopLocations);
    if (!mounted) {
      return;
    }
    try {
      http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        var routeGeometry = data['routes'][0]['geometry'];

        var coordinates = routeGeometry['coordinates'].toList();

        await mapboxMap?.style.addSource(
          mapbox.GeoJsonSource(
            id: "route_$routeId",
            data: json.encode({
              "type": "Feature",
              "geometry": {"type": "LineString", "coordinates": coordinates},
            }),
          ),
        );

        await mapboxMap?.style.addLayer(
          mapbox.LineLayer(
            id: "route_layer_$routeId",
            sourceId: "route_$routeId",
            lineJoin: mapbox.LineJoin.ROUND,
            lineCap: mapbox.LineCap.ROUND,
            lineColor: const Color.fromARGB(255, 255, 150, 150).toARGB32(),
            lineWidth: 3.0,
            slot: "bottom",
          ),
        );

        mapboxMap?.annotations.createPointAnnotationManager().then((manager) {
          pointAnnotationManager = manager;
          pointAnnotationManager?.deleteAll();
          for (var busStop in busStopLocations) {
            _createMarker(busStop);
          }
        });

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to fetch route data. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _drawBusPath(double latitude, double longitude) async {
    if (!mounted) return;

    try {
      await _fetchUserLocation(context);

      http.Response response = await http.post(
        Uri.parse(bus_path_endpoint),
        body: json.encode({
          "user_longitude": userLocation?.longitude ?? 0.0,
          "user_latitude": userLocation?.latitude ?? 0.0,
          "longitude": longitude,
          "latitude": latitude,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        var coordinates = data['coordinates'].toList();

        // Check if source already exists and remove it
        try {
          await mapboxMap?.style.removeStyleLayer("bus_path_layer");
        } catch (e) {
          // Layer doesn't exist, which is fine
        }

        try {
          await mapboxMap?.style.removeStyleSource("bus_path");
        } catch (e) {
          // Source doesn't exist, which is fine
        }

        await mapboxMap?.style.addSource(
          mapbox.GeoJsonSource(
            id: "bus_path",
            data: json.encode({
              "type": "Feature",
              "geometry": {"type": "LineString", "coordinates": coordinates},
            }),
          ),
        );

        await mapboxMap?.style.addLayer(
          mapbox.LineLayer(
            id: "bus_path_layer",
            sourceId: "bus_path",
            lineJoin: mapbox.LineJoin.ROUND,
            lineCap: mapbox.LineCap.ROUND,
            lineDasharray: [2.0, 1.5, 0.5, 1.5],
            lineColor: const Color(0xFF14213D).toARGB32(),
            lineWidth: 4.0,
            lineOpacity: 0.8,
          ),
        );
      } else {
        setState(() {
          errorMessage =
              'Failed to draw bus path. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to draw bus path: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchBusStops() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Ensure token is initialized
      if (token == null || token!.isEmpty) {
        await _initializeToken();
      }

      if (token == null || token!.isEmpty) {
        throw Exception('Authentication token not found');
      }

      List<BusStop> stops = await getAllBusStopsByRouteId(routeId, token!);

      setState(() {
        busStopLocations = stops;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  void _onMapCreated(mapbox.MapboxMap mapBoxMap) {
    mapboxMap = mapBoxMap;
    _drawRouteAndStops();

    if (busStopLocations.isNotEmpty) {
      mapBoxMap.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: busStopLocations[0].position),
          zoom: 12.0,
        ),
        mapbox.MapAnimationOptions(duration: 2000),
      );
    }
  }

  void _addUserMarker(mapbox.Point uerLocation) {
    mapboxMap?.location.updateSettings(
      mapbox.LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingColor: const Color(0xFF14213D).toARGB32(),
        pulsingMaxRadius: 30.0,
      ),
    );
  }

  void _createMarker(BusStop stop) {
    pointAnnotationManager
        ?.create(
          mapbox.PointAnnotationOptions(
            geometry: mapbox.Point(coordinates: stop.position),
            iconImage: "bus",
            textField: stop.name,
            textSize: 12.0,
            textColor: const Color(0xFF14213D).toARGB32(),
            textHaloColor: Colors.white.toARGB32(),
            textHaloWidth: 2.0,
            iconColor: const Color(0xFF14213D).toARGB32(),
            iconSize: 1.2,
            iconOffset: [0.0, -5.0],
            textOffset: [0.0, 1.0],
            textAnchor: mapbox.TextAnchor.TOP,
            iconAnchor: mapbox.IconAnchor.BOTTOM,
          ),
        )
        .then(
          (annotation) => {
            setState(() {
              pointAnnotations?.add(annotation);
            }),
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF14213D),
        foregroundColor: Colors.white,
        title: Text(
          'Bus Route Map',
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
              tooltip: 'Refresh Bus Stops',
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                _fetchBusStops();
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
              icon: const Icon(Icons.alt_route_rounded, color: Colors.white),
              tooltip: 'Select Route',
              onPressed: () {
                _openModal(context);
              },
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  void _openModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      pageBuilder: (contxt, animation1, animation2) {
        return Container();
      },
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation1, animation2, widget) {
        return ScaleTransition(
          scale: Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation1, curve: Curves.elasticOut),
          ),
          child: FadeTransition(
            opacity: Tween(begin: 0.0, end: 1.0).animate(animation1),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              backgroundColor: Colors.white,
              elevation: 10,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14213D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.alt_route_rounded,
                      color: Color(0xFF14213D),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Select Route',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF14213D),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.3,
                child: Column(
                  children: [
                    Text(
                      'Choose a bus route to display on the map',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child:
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ListView.builder(
                                itemCount: routes.length,
                                itemBuilder: (context, index) {
                                  bool isSelected = routes[index] == routeId;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      gradient:
                                          isSelected
                                              ? const LinearGradient(
                                                colors: [
                                                  Color(0xFF14213D),
                                                  Color(0xFF2A3F5F),
                                                ],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              )
                                              : null,
                                      color:
                                          isSelected ? null : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? const Color(0xFF14213D)
                                                : Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              isSelected
                                                  ? Colors.white.withOpacity(
                                                    0.2,
                                                  )
                                                  : const Color(
                                                    0xFF14213D,
                                                  ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.directions_bus_rounded,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF14213D),
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        'Route ${routes[index]}',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF14213D),
                                        ),
                                      ),
                                      trailing:
                                          isSelected
                                              ? const Icon(
                                                Icons.check_circle_rounded,
                                                color: Colors.white,
                                              )
                                              : const Icon(
                                                Icons.radio_button_unchecked,
                                                color: Colors.grey,
                                              ),
                                      onTap: () {
                                        if (routes[index] != routeId) {
                                          setState(() {
                                            routeId = routes[index];
                                            isLoading = true;
                                            errorMessage = null;
                                          });
                                          Navigator.of(context).pop();
                                          _fetchBusStops();
                                          BeautifulAlerts.showSuccessSnackBar(
                                            context,
                                            'Switched to Route ${routes[index]}',
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomDrawerContainer(BuildContext context) {
    double height = MediaQuery.of(context).size.height * 0.4;
    double width = MediaQuery.of(context).size.width;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(25.0),
        topRight: Radius.circular(25.0),
      ),
      child: GestureDetector(
        onPanEnd: (details) {
          if (details.velocity.pixelsPerSecond.dy > 50) {
            setState(() {
              isDrawerOpen = false;
            });
          } else if (details.velocity.pixelsPerSecond.dy < -50) {
            setState(() {
              isDrawerOpen = true;
            });
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF14213D), Color(0xFF2A3F5F)],
            ),
          ),
          width: width,
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 20.0,
            ),
            child: Column(
              children: [
                // Drawer handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedRotation(
                  curve: Curves.easeInOut,
                  turns: isDrawerOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${busStopLocations.length} stops available',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: busStopLocations.length,
                    itemBuilder: (context, index) {
                      BusStop stop = busStopLocations[index];
                      return GestureDetector(
                        onTap: () {
                          _drawBusPath(stop.latitude, stop.longitude);
                          mapboxMap?.flyTo(
                            mapbox.CameraOptions(
                              center: mapbox.Point(coordinates: stop.position),
                              zoom: 15.0,
                            ),
                            mapbox.MapAnimationOptions(duration: 1000),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF14213D,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.directions_bus_rounded,
                                  color: Color(0xFF14213D),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stop.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF14213D),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Stop ${index + 1} of ${busStopLocations.length}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14213D),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.navigation_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  color: Color(0xFF14213D),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading Bus Route Map...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF14213D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we fetch the latest route data',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Something went wrong',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF14213D),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    errorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      errorMessage = null;
                    });
                    _fetchBusStops();
                    _fetchRoutes();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14213D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    'Try Again',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        mapbox.MapWidget(
          styleUri: mapbox.MapboxStyles.LIGHT,
          onMapCreated: _onMapCreated,
        ),
        AnimatedPositioned(
          curve: Curves.easeInOut,
          duration: const Duration(milliseconds: 300),
          left: 0,
          bottom:
              (isDrawerOpen)
                  ? 0
                  : -MediaQuery.of(context).size.height * 0.4 + 90,
          child: _buildBottomDrawerContainer(context),
        ),
        AnimatedPositioned(
          curve: Curves.easeInOut,
          duration: const Duration(milliseconds: 300),
          bottom:
              isDrawerOpen
                  ? MediaQuery.of(context).size.height * 0.4 + 100
                  : 210,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF14213D), Color(0xFF2A3F5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF14213D).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () async {
                  await _fetchNearestStop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Icon(
                    Icons.directions_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedPositioned(
          curve: Curves.easeInOut,
          duration: const Duration(milliseconds: 300),
          bottom:
              isDrawerOpen
                  ? MediaQuery.of(context).size.height * 0.4 + 20
                  : 130,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap:
                    !myLocationClicked
                        ? () async {
                          setState(() {
                            myLocationClicked = true;
                          });
                          await _fetchUserLocation(context);
                          if (userLocation != null) {
                            mapboxMap?.flyTo(
                              mapbox.CameraOptions(
                                center: mapbox.Point(
                                  coordinates: mapbox.Position(
                                    userLocation!.longitude,
                                    userLocation!.latitude,
                                  ),
                                ),
                                zoom: 14.0,
                              ),
                              mapbox.MapAnimationOptions(duration: 300),
                            );
                            BeautifulAlerts.showSuccessSnackBar(
                              context,
                              'Location found successfully!',
                            );
                          }
                          setState(() {
                            myLocationClicked = false;
                          });
                        }
                        : null,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child:
                      myLocationClicked
                          ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(
                            Icons.my_location_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
