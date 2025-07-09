import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/Aboutus.dart';
import 'package:murir_tin/BookTicket.dart';
import 'package:murir_tin/BookingHistory.dart';
import 'package:murir_tin/ComplainBox.dart';
import 'package:murir_tin/ComplainStatus.dart';

import 'package:murir_tin/LiveMap.dart';
import 'package:murir_tin/Login.dart';
import 'package:murir_tin/Profile.dart';
import 'package:murir_tin/SOS.dart';
import 'package:murir_tin/bus_map.dart';
import 'package:murir_tin/social_issues_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:murir_tin/api.dart';
import 'dart:convert';

class Landingpage extends StatefulWidget {
  const Landingpage({super.key});

  @override
  State<Landingpage> createState() => _LandingpageState();
}

class _LandingpageState extends State<Landingpage> with WidgetsBindingObserver {
  String? username;
  String? email;
  String _locationMessage = "Fetching location...";
  double? _latitude;
  double? _longitude;
  String? _address;
  bool _isLoading = true;
  String? _errorMessage;
  String? profilePicUrl;
  final _storage = const FlutterSecureStorage();
  StreamSubscription<Position>? _positionStream;
  String _imageVersion = ''; //avoiding memory leak

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkAndRequestPermissions();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _refreshUserData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only reload if we're not currently loading
    if (!_isLoading) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(landing_page_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          username = userData['username'];
          email = userData['email'];
          profilePicUrl = userData['profile_pic_url'];
          // Update image version to force refresh
          _imageVersion = DateTime.now().millisecondsSinceEpoch.toString();
          _isLoading = false;
        });
      } else {
        debugPrint('Failed to load profile: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add method to refresh user data
  Future<void> _refreshUserData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUserData();
  }

  Widget _buildProfileAvatar({required double radius, double? iconSize}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child:
          profilePicUrl != null && profilePicUrl!.isNotEmpty
              ? ClipOval(
                child: Image.network(
                  '${profilePicUrl!}?v=$_imageVersion', // Use the stored image version
                  fit: BoxFit.cover,
                  width: radius * 2,
                  height: radius * 2,
                  // Add cache headers to prevent caching
                  headers: {
                    'Cache-Control': 'no-cache, no-store, must-revalidate',
                    'Pragma': 'no-cache',
                    'Expires': '0',
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error loading profile image: $error');
                    return Icon(
                      Icons.person,
                      size: iconSize ?? radius,
                      color: Color(0xFF14213D),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: radius * 2,
                      height: radius * 2,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF14213D),
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    );
                  },
                ),
              )
              : Icon(
                Icons.person,
                size: iconSize ?? radius,
                color: Color(0xFF14213D),
              ),
    );
  }

  Future<void> _checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage = "Location services are disabled.";
        _isLoading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = "Location permissions are denied.";
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage = "Location permissions are permanently denied.";
        _isLoading = false;
      });
      return;
    }

    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _updateLocationMessage(position);

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      ).listen((Position newPosition) async {
        await _updateLocationMessage(newPosition);
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error getting location: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLocationMessage(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks.first;

      String area =
          place.subLocality ??
          place.locality ??
          place.administrativeArea ??
          "Unknown Area";
      String city =
          place.locality ?? place.administrativeArea ?? "Unknown City";
      String country = place.country ?? "Unknown Country";

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _address = "$area, $city, $country";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _address = "Unable to fetch area";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive calculations
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Dynamic font sizes based on screen width
    final largeFontSize = screenWidth * 0.07; // e.g. 7% of screen width
    final mediumFontSize = screenWidth * 0.045;
    final smallFontSize = screenWidth * 0.035;

    // Determine grid column count based on screen width
    int gridCrossAxisCount = (screenWidth ~/ 180).clamp(
      1,
      2,
    ); // max 2 columns for mobile

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Home",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF14213D), Color(0xFF4B6EAF)],
              begin: Alignment.topRight,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF14213D)),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF14213D), Color(0xFF4B6EAF)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: screenWidth * 0.1,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: screenWidth * 0.13,
                      color: const Color(0xFF14213D),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    username ?? "Loading...",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: mediumFontSize,
                    ),
                  ),
                  Text(
                    email ?? "",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: smallFontSize,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text('Home', style: GoogleFonts.poppins(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('Profile', style: GoogleFonts.poppins(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(
                'Booking History',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => Bookinghistory(username: username ?? ''),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.hourglass_bottom),
              title: Text(
                'Complain status',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComplaintStatusScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.forum),
              title: Text(
                'Social Issues',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SocialIssuesScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sos),
              title: Text(
                'Emergency SOS',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SOS()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: Text('About us', style: GoogleFonts.poppins(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Aboutus()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text('Sign out', style: GoogleFonts.poppins(fontSize: 16)),
              onTap: () async {
                // Clear stored data
                await _storage.delete(key: 'jwt_token');
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${username ?? ''}!',
                style: GoogleFonts.poppins(
                  fontSize: largeFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF14213D),
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              Text(
                'Explore your journey',
                style: GoogleFonts.poppins(
                  fontSize: mediumFontSize,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),

              // Location info with responsive layout
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Current Latitude: ${_latitude?.toStringAsFixed(4) ?? '...'}",
                    style: GoogleFonts.poppins(fontSize: smallFontSize),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    "Current Longitude: ${_longitude?.toStringAsFixed(4) ?? '...'}",
                    style: GoogleFonts.poppins(fontSize: smallFontSize),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.012),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    size: smallFontSize * 1.4,
                    color: const Color.fromARGB(255, 5, 1, 51),
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  Expanded(
                    child: Text(
                      "Current Location: ${_address ?? 'Updating...'}",
                      style: GoogleFonts.poppins(
                        fontSize: smallFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.01),

              Row(
                children: [
                  Icon(
                    Icons.notification_important,
                    size: smallFontSize * 1.6,
                    color: const Color.fromARGB(255, 9, 4, 56),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Text(
                      "Use QR to book ticket instantly",
                      style: GoogleFonts.poppins(
                        fontSize: smallFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.005),
              Row(
                children: [
                  Icon(
                    Icons.notification_important,
                    size: smallFontSize * 1.6,
                    color: const Color.fromARGB(255, 9, 4, 56),
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Expanded(
                    child: Text(
                      "Report issues easily using the Complain Box",
                      style: GoogleFonts.poppins(
                        fontSize: smallFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.025),

              Text(
                "Quick Actions",
                style: GoogleFonts.poppins(fontSize: mediumFontSize),
              ),
              SizedBox(height: screenHeight * 0.02),

              Expanded(
                child: GridView.count(
                  crossAxisCount: gridCrossAxisCount,
                  crossAxisSpacing: screenWidth * 0.04,
                  mainAxisSpacing: screenHeight * 0.025,
                  children: [
                    _buildFeatureTile(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Book Ticket',
                      fontSize: mediumFontSize,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Bookticket()),
                        );
                      },
                    ),
                    _buildFeatureTile(
                      icon: Icons.feedback,
                      label: 'Complain Box',
                      fontSize: mediumFontSize,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ComplaintBoxScreen(
                                  username: username,
                                  email: email,
                                  profilePicUrl: profilePicUrl,
                                ),
                          ),
                        );
                      },
                    ),
                    _buildFeatureTile(
                      icon: Icons.location_on,
                      label: 'Live Map',
                      fontSize: mediumFontSize,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Livemap()),
                        );
                      },
                    ),
                    _buildFeatureTile(
                      icon: Icons.directions_bus_filled,
                      label: 'Find My Bus',
                      fontSize: mediumFontSize,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BusMap()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double fontSize,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF14213D), Color(0xFF4B6EAF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: fontSize * 3, color: Colors.white),
            SizedBox(height: fontSize * 0.7),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
