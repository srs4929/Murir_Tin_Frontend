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

class PickupSelectionScreen extends StatefulWidget {
  final String routeId;
  final BusStop? selectedPickup;

  const PickupSelectionScreen({
    super.key,
    required this.routeId,
    this.selectedPickup,
  });

  @override
  State<PickupSelectionScreen> createState() => _PickupSelectionScreenState();
}

class _PickupSelectionScreenState extends State<PickupSelectionScreen>
    with TickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();

  List<BusStopWithDistance> _busStops = [];
  bool _loadingStops = false;
  bool _loadingLocation = false;
  Position? _currentPosition;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentLocation();
    _loadBusStopsWithDistance();
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
        _loadBusStopsWithDistance();
      }
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      setState(() {
        _loadingLocation = false;
      });
    }
  }

  Future<void> _loadBusStopsWithDistance() async {
    setState(() {
      _loadingStops = true;
      _busStops.clear();
    });

    try {
      final token = await _getJwtToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$bus_stops_endpoint/${widget.routeId}'),
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

        // Sort by distance (nearest first) if location is available
        if (_currentPosition != null) {
          stopsWithDistance.sort(
            (a, b) => a.distanceInMeters.compareTo(b.distanceInMeters),
          );
        }

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
          'Select Pickup Location',
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
                // Location status
                if (_loadingLocation)
                  Container(
                    margin: const EdgeInsets.all(16),
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
                    margin: EdgeInsets.fromLTRB(
                      16,
                      _loadingLocation ? 0 : 16,
                      16,
                      0,
                    ),
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
                                Icons.my_location,
                                color: const Color(0xFF4B6EAF),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _currentPosition != null
                                    ? 'Nearest Pickup Locations'
                                    : 'Available Pickup Locations',
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
              'No pickup locations available',
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
        final isSelected = widget.selectedPickup?.name == stop.name;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? const Color(0xFF4B6EAF).withOpacity(0.1)
                    : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color:
                  isSelected ? const Color(0xFF4B6EAF) : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
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
                color:
                    isSelected
                        ? const Color(0xFF4B6EAF)
                        : const Color(0xFF4B6EAF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasLocation && index == 0 ? Icons.near_me : Icons.my_location,
                color: isSelected ? Colors.white : const Color(0xFF4B6EAF),
                size: 20,
              ),
            ),
            title: Text(
              stop.name,
              style: GoogleFonts.poppins(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color:
                    isSelected
                        ? const Color(0xFF4B6EAF)
                        : const Color(0xFF14213D),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasLocation && index == 0)
                  Container(
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
                  ),
                const SizedBox(width: 8),
                isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xFF4B6EAF))
                    : const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
              ],
            ),
            onTap: () {
              // Return the selected pickup location
              Navigator.pop(context, stop);
            },
          ),
        );
      },
    );
  }
}
