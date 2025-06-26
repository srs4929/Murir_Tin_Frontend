import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/BookTicket.dart';
import 'package:murir_tin/BookingHistory.dart';
import 'package:murir_tin/ComplainBox.dart';
import 'package:murir_tin/ComplainStatus.dart';
import 'package:murir_tin/FindBus.dart';
import 'package:murir_tin/LiveMap.dart';
import 'package:murir_tin/Login.dart';
import 'package:murir_tin/Profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class Landingpage extends StatefulWidget {
  const Landingpage({super.key});

  @override
  State<Landingpage> createState() => _LandingpageState();
}

class _LandingpageState extends State<Landingpage> {
  String? username;
  String? email;
  String _locationMessage = "Fetching location...";
  double? _latitude;
  double? _longitude;
  String? _address;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkAndRequestPermissions();
  }

  Future<void> _loadUserData() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId != null) {
      final response =
          await supabase
              .from('user_profiles')
              .select('username, email')
              .eq('id', userId)
              .single();

      setState(() {
        username = response['username'];
        email = response['email'];
      });
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage = "Location services are disabled.";
        _isLoading = false;
      });
      return;
    }

    // Check and request permission
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

    // Get initial location and start listening for updates
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Get initial position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _updateLocationMessage(position);

      // Listen for location updates
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update when user moves 10 meters
        ),
      ).listen((Position position) async {
        await _updateLocationMessage(position);
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
      Placemark place = placemarks[0];
      String fullAddress =
          "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _address = fullAddress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _address = "Unable to fetch address";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Home",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
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
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: Color(0xFF14213D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    username ?? "Loading...",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    email ?? "",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Landingpage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Profile()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.receipt_long),
              title: Text('Booking History', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Bookinghistory(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.hourglass_bottom),
              title: Text('Complain status', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Complainstatus(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sign out', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align left
            children: [
              Text(
                'Welcome, ${username ?? ''}!',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14213D),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Explore your journey',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 20),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Latitude icon
                      SizedBox(width: 8),
                      Text("Current Latitude: $_latitude"),
                    ],
                  ),

                  Row(
                    children: [
                   
                      SizedBox(width: 8),
                      Text("Current Longitude: $_longitude"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 22,
                        color: const Color.fromARGB(255, 5, 1, 51),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Current Location: $_address",
                          style: GoogleFonts.poppins(fontSize: 14,
                          fontWeight:FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height:3),
                  Row(
                    children: [
                      Icon(
                        Icons.notification_important,
                        size:28,
                        color: const Color.fromARGB(255, 9, 4, 56),
                      ), // Longitude icon
                      SizedBox(width: 8),
                      Text("Use QR to book ticket instantly",
                      style:GoogleFonts.poppins(
                         fontSize: 14,
                         fontWeight: FontWeight.w500
                      )),
                    ],
                  ),
                  const SizedBox(height:3),
                   Row(
                    children: [
                      Icon(
                        Icons.notification_important,
                        size:28,
                        color: const Color.fromARGB(255, 9, 4, 56),
                      ), // Longitude icon
                      SizedBox(width: 2),
                      Text("Report issues easily using the Complain Box",
                      style:GoogleFonts.poppins(
                         fontSize: 14,
                         fontWeight: FontWeight.w500
                      )),
                    ],
                  )
                ],
              ),
              /* CarouselSlider(
                options: CarouselOptions(
                  height: 160,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.85,
                ),
                items: [
                  _buildCarouselItem(
                    "Use QR to book tickets instantly!",
                    Icons.qr_code,
                  ),
                  _buildCarouselItem(
                    "Track your bus live on the map!",
                    Icons.location_on,
                  ),
                  _buildCarouselItem(
                    "Report issues easily using the Complain Box.",
                    Icons.feedback,
                  ),
                  _buildCarouselItem(
                    "Save your favorite routes for quick access!",
                    Icons.favorite,
                  ),
                ],
              ),*/
              const SizedBox(height: 30),
              Text("Quick Actions", style: GoogleFonts.poppins(fontSize: 18)),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildFeatureTile(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Book Ticket',
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Complainbox(),
                          ),
                        );
                      },
                    ),
                    _buildFeatureTile(
                      icon: Icons.location_on,
                      label: 'Live Map',
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Findbus()),
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
}

Widget _buildFeatureTile({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
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
          Icon(icon, size: 56, color: Colors.white),
          const SizedBox(height: 14),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

/*Widget _buildCarouselItem(String text, IconData icon) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 5),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        colors: [Color(0xFF4B6EAF), Color(0xFF14213D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.white, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}*/
