import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/Aboutus.dart';
import 'package:murir_tin/BookTicket.dart';
import 'package:murir_tin/BookingHistory.dart';
import 'package:murir_tin/ComplainBox.dart';
import 'package:murir_tin/ComplainStatus.dart';
import 'package:murir_tin/Providers/user_provider.dart';
import 'package:murir_tin/LiveBusTracker.dart';
import 'package:murir_tin/Login.dart';
import 'package:murir_tin/Profile.dart';
import 'package:murir_tin/SOS.dart';
import 'package:murir_tin/bus_map.dart';
import 'package:murir_tin/social_issues_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class Landingpage extends ConsumerStatefulWidget {
  const Landingpage({super.key});

  @override
  ConsumerState<Landingpage> createState() => _LandingpageState();
}

class _LandingpageState extends ConsumerState<Landingpage>
    with WidgetsBindingObserver {
  String? _address;
  bool _isLoading = true;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    // Load user data using Riverpod
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).loadUser();
    });
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
      ref.read(userProvider.notifier).loadUser();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only reload if we're not currently loading
    if (!_isLoading) {
      ref.read(userProvider.notifier).loadUser();
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
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
        _address = "$area, $city, $country";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _address = "Unable to fetch area";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get user data from Riverpod providers
    final userName = ref.watch(userNameProvider);
    final userEmail = ref.watch(userEmailProvider);
    final userProfilePic = ref.watch(userProfilePicProvider);

    // Responsive calculations
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Dynamic font sizes based on screen width
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
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child:
                    userProfilePic != null && userProfilePic.isNotEmpty
                        ? ClipOval(
                          child: Image.network(
                            userProfilePic,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Icon(
                                  Icons.person,
                                  color: Color(0xFF14213D),
                                ),
                          ),
                        )
                        : Icon(Icons.person, color: Color(0xFF14213D)),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Enhanced Header with original theme
            Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF14213D), Color(0xFF4B6EAF)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // Subtle background patterns
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    // User Profile Content
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Enhanced Profile Picture
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white,
                              child:
                                  userProfilePic != null &&
                                          userProfilePic.isNotEmpty
                                      ? ClipOval(
                                        child: Image.network(
                                          userProfilePic,
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  _buildAvatarFallback(
                                                    userName,
                                                    screenWidth,
                                                  ),
                                        ),
                                      )
                                      : _buildAvatarFallback(
                                        userName,
                                        screenWidth,
                                      ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // User Name with enhanced styling
                          Flexible(
                            child: Text(
                              userName.isEmpty ? "Loading..." : userName,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // User Email
                          Flexible(
                            child: Text(
                              userEmail,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Enhanced Menu Items
            _buildDrawerItem(context, Icons.person_rounded, 'Profile', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyProfileScreen()),
              );
            }),

            _buildDrawerItem(
              context,
              Icons.receipt_long_rounded,
              'Booking History',
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Bookinghistory(username: userName),
                  ),
                );
              },
            ),

            _buildDrawerItem(
              context,
              Icons.schedule_rounded,
              'Complaint Status',
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComplaintStatusScreen(),
                  ),
                );
              },
            ),

            _buildDrawerItem(context, Icons.forum_rounded, 'Social Issues', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SocialIssuesScreen()),
              );
            }),

            _buildDrawerItem(
              context,
              Icons.emergency_rounded,
              'Emergency SOS',
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SOS()),
                );
              },
              iconColor: Colors.red[600],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Divider(color: Colors.grey),
            ),

            _buildDrawerItem(context, Icons.info_rounded, 'About Us', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Aboutus()),
              );
            }),

            _buildDrawerItem(
              context,
              Icons.logout_rounded,
              'Sign Out',
              () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                  );
                }
              },
              iconColor: Colors.red[600],
            ),

            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
      body: SafeArea(
        child: _buildHomeContent(
          context,
          userName,
          userEmail,
          userProfilePic,
          screenWidth,
          screenHeight,
          mediumFontSize,
          smallFontSize,
          gridCrossAxisCount,
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

  Widget _buildAvatarFallback(String userName, double screenWidth) {
    final initials =
        userName.isNotEmpty
            ? userName
                .split(' ')
                .map((e) => e.isNotEmpty ? e[0] : '')
                .take(2)
                .join('')
                .toUpperCase()
            : 'U';

    return Container(
      width: screenWidth * 0.2,
      height: screenWidth * 0.2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A90E2), Color(0xFF2F4F78)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(
    BuildContext context,
    String userName,
    String userEmail,
    String? userProfilePic,
    double screenWidth,
    double screenHeight,
    double mediumFontSize,
    double smallFontSize,
    int gridCrossAxisCount,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.02,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.only(bottom: screenHeight * 0.02),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF14213D), Color(0xFF4B6EAF)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF14213D).withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        userName.isEmpty ? 'Guest User' : userName,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (userEmail.isNotEmpty)
                        Text(
                          userEmail,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.person_outline, color: Colors.white70, size: 24),
              ],
            ),
          ),

          Text(
            'Explore your journey',
            style: GoogleFonts.poppins(
              fontSize: mediumFontSize,
              color: const Color(0xFF14213D),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
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
          SizedBox(height: screenHeight * 0.01),

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
                              username: userName,
                              email: userEmail,
                              profilePicUrl: userProfilePic ?? '',
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
                      MaterialPageRoute(builder: (context) => LiveBusTracker()),
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
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color:
                iconColor?.withOpacity(0.1) ??
                const Color(0xFF14213D).withOpacity(0.1),
          ),
          child: Icon(
            icon,
            color: iconColor ?? const Color(0xFF14213D),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: 14,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: const Color(0xFF14213D).withOpacity(0.05),
        splashColor: const Color(0xFF14213D).withOpacity(0.1),
      ),
    );
  }
}
