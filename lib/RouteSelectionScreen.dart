import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:murir_tin/api.dart';
import 'package:murir_tin/Models/bus_stop.dart';
import 'package:murir_tin/Models/bus_stop_with_distance.dart';
import 'package:murir_tin/Services/location_handler.dart';
import 'package:murir_tin/utils/beautiful_alerts.dart';

class RouteSelectionScreen extends StatefulWidget {
  final String? selectedRoute;

  const RouteSelectionScreen({super.key, this.selectedRoute});

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen>
    with TickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();

  List<String> _availableRoutes = [];
  String? _selectedRoute;
  List<BusStopWithDistance> _busStops = [];
  bool _loadingRoutes = false;
  bool _loadingStops = false;
  bool _loadingLocation = false;
  Position? _currentPosition;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedRoute = widget.selectedRoute;
    _initializeAnimations();
    _loadAvailableRoutes();
    _getCurrentLocation();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _loadingLocation = true;
    });

    try {
      final position = await getCurrentLocation(context);
      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
        if (_selectedRoute != null) {
          _loadBusStopsWithDistance(_selectedRoute!);
        }
      }
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      setState(() {
        _loadingLocation = false;
      });
    }
  }

  Future<void> _loadAvailableRoutes() async {
    setState(() {
      _loadingRoutes = true;
    });

    try {
      final token = await _getJwtToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse(bus_routes_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> routesJson = json.decode(response.body);
        setState(() {
          _availableRoutes =
              routesJson.map((route) {
                if (route is String) {
                  return route;
                } else if (route is Map<String, dynamic>) {
                  return route['route_id']?.toString() ??
                      route['name']?.toString() ??
                      route.toString();
                } else {
                  return route.toString();
                }
              }).toList();
        });
      }
    } catch (e) {
      print('Error loading routes: $e');
      _showErrorDialog('Failed to load routes: ${e.toString()}');
    } finally {
      setState(() {
        _loadingRoutes = false;
      });
    }
  }

  Future<void> _loadBusStopsWithDistance(String routeId) async {
    setState(() {
      _loadingStops = true;
      _busStops.clear();
    });

    try {
      final token = await _getJwtToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$bus_stops_endpoint/$routeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> stopsJson = json.decode(response.body);
        final stops = stopsJson.map((json) => BusStop.fromMap(json)).toList();

        // Calculate distance and walking time for each stop
        List<BusStopWithDistance> stopsWithDistance = [];
        for (var stop in stops) {
          double distance = 0;
          double walkingTime = 0;

          if (_currentPosition != null) {
            // Calculate distance in meters
            distance = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              stop.latitude,
              stop.longitude,
            );

            // Calculate walking time (assuming average walking speed of 5 km/h = 1.39 m/s)
            walkingTime = distance / 1.39; // in seconds
          }

          stopsWithDistance.add(
            BusStopWithDistance(
              busStop: stop,
              distanceInMeters: distance,
              walkingTimeInSeconds: walkingTime,
            ),
          );
        }

        // Sort by distance (nearest first)
        stopsWithDistance.sort(
          (a, b) => a.distanceInMeters.compareTo(b.distanceInMeters),
        );

        setState(() {
          _busStops = stopsWithDistance;
        });
      }
    } catch (e) {
      print('Error loading bus stops: $e');
      _showErrorDialog('Failed to load bus stops: ${e.toString()}');
    } finally {
      setState(() {
        _loadingStops = false;
      });
    }
  }

  Future<String?> _getJwtToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      _showErrorDialog('You are not logged in. Please log in to continue.');
      return null;
    }
    return token;
  }

  void _showErrorDialog(String message) {
    BeautifulAlerts.showErrorDialog(context, title: "Error", message: message);
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatWalkingTime(double walkingTimeInSeconds) {
    if (walkingTimeInSeconds < 60) {
      return '${walkingTimeInSeconds.round()} sec';
    } else {
      final minutes = (walkingTimeInSeconds / 60).round();
      return '$minutes min';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Route',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Route selection section
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF14213D), Color(0xFF4B6EAF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4B6EAF).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.route,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Choose Your Route',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_loadingRoutes)
                        const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedRoute,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            hintText: 'Select a route',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          dropdownColor: const Color(0xFF14213D),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          items:
                              _availableRoutes.map((route) {
                                return DropdownMenuItem(
                                  value: route,
                                  child: Text(
                                    route,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRoute = value;
                            });
                            if (value != null) {
                              _loadBusStopsWithDistance(value);
                            }
                          },
                        ),
                    ],
                  ),
                ),

                // Location status
                if (_loadingLocation)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Getting your location...',
                          style: GoogleFonts.poppins(
                            color: Colors.orange,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Bus stops list
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: const Color(0xFF4B6EAF),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _currentPosition != null
                                    ? 'Nearest Bus Stops'
                                    : 'Bus Stops',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF14213D),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (_currentPosition == null)
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  color: const Color(0xFF4B6EAF),
                                  onPressed: _getCurrentLocation,
                                ),
                            ],
                          ),
                        ),

                        // Bus stops list
                        Expanded(child: _buildBusStopsList()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusStopsList() {
    if (_selectedRoute == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Please select a route first',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_loadingStops) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4B6EAF)),
      );
    }

    if (_busStops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bus_alert, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No bus stops found for this route',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _busStops.length,
      itemBuilder: (context, index) {
        final stopWithDistance = _busStops[index];
        final stop = stopWithDistance.busStop;
        final hasLocation = _currentPosition != null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4B6EAF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasLocation && index == 0 ? Icons.near_me : Icons.location_on,
                color: const Color(0xFF4B6EAF),
                size: 20,
              ),
            ),
            title: Text(
              stop.name,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF14213D),
                fontSize: 16,
              ),
            ),
            subtitle:
                hasLocation
                    ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.straighten,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatDistance(stopWithDistance.distanceInMeters),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              '${_formatWalkingTime(stopWithDistance.walkingTimeInSeconds)} walk',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                    : Text(
                      'Location needed for distance',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
            trailing:
                hasLocation && index == 0
                    ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Nearest',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                    : const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
            onTap: () {
              // Return the selected route and bus stop
              Navigator.pop(context, {
                'route': _selectedRoute,
                'busStop': stop,
              });
            },
          ),
        );
      },
    );
  }
}
