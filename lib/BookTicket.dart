import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:murir_tin/Component.dart';
import 'package:murir_tin/Checkout.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:murir_tin/api.dart';
import 'package:murir_tin/Models/bus_stop.dart';
import 'package:murir_tin/RouteSelectionScreen.dart';
import 'package:murir_tin/DestinationSelectionScreen.dart';
import 'package:murir_tin/PickupSelectionScreen.dart';
import 'utils/beautiful_alerts.dart';

class Bookticket extends StatefulWidget {
  const Bookticket({super.key});

  @override
  State<Bookticket> createState() => _BookticketState();
}

class _BookticketState extends State<Bookticket> with TickerProviderStateMixin {
  final TextEditingController ticketController = TextEditingController();
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int? _ticketCount;
  int? _totalCost;
  String? _bookingId;
  bool _isLoading = false;

  String? _selectedRoute;
  BusStop? _selectedFromStop;
  BusStop? _selectedToStop;
  bool _loadingStops = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    ticketController.dispose();
    fromController.dispose();
    toController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    BeautifulAlerts.showErrorDialog(context, title: "Error", message: message);
  }

  void _showSuccessDialog(String message) {
    BeautifulAlerts.showSuccessDialog(
      context,
      title: "Success",
      message: message,
    );
  }

  Future<String?> _getJwtToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      _showErrorDialog('You are not logged in. Please log in to book tickets.');
      return null;
    } else {
      return token;
    }
  }

  Future<void> bookTickets() async {
    final from = _selectedFromStop?.name ?? fromController.text.trim();
    final to = _selectedToStop?.name ?? toController.text.trim();
    final count = int.tryParse(ticketController.text.trim()) ?? 0;

    if (from.isEmpty || to.isEmpty || count <= 0) {
      _showErrorDialog("Please fill all fields correctly.");
      return;
    }

    if (count > 4) {
      _showErrorDialog("You cannot book more than 4 seats.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _getJwtToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse(ticket_book_endpoint),
        headers: headers,
        body: json.encode({
          'route_id': _selectedRoute,
          'from_location': from,
          'from_location_long': _selectedFromStop?.longitude,
          'from_location_lat': _selectedFromStop?.latitude,
          'to_location': to,
          'to_location_long': _selectedToStop?.longitude,
          'to_location_lat': _selectedToStop?.latitude,
          'ticket_count': count,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);

        setState(() {
          _ticketCount = responseData['ticket_count'];
          _totalCost = responseData['total_cost'];
          _bookingId = responseData['booking_id'];
        });

        _showSuccessDialog("Booking successful! Total cost: ৳$_totalCost");
      } else {
        String errorMessage = "Booking failed";
        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['detail'] ??
              errorData['message'] ??
              "An unknown error occurred.";
        } catch (e) {
          // If JSON parsing fails, use the raw response body if it's short
          if (response.body.isNotEmpty && response.body.length < 200) {
            errorMessage = response.body;
          } else {
            errorMessage = "Server returned status ${response.statusCode}";
          }
        }
        _showErrorDialog(errorMessage);
      }
    } on http.ClientException catch (e) {
      _showErrorDialog(
        "Network error: Failed to connect to the server. Is FastAPI running? (${e.message})",
      );
    } on FormatException catch (e) {
      _showErrorDialog("Server returned invalid response format: ${e.message}");
    } catch (e) {
      print('DEBUG: Booking error details: $e');
      _showErrorDialog("An unexpected error occurred: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: const GAppBar(title: "Book Ticket"),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  bottom: 160,
                  top: 20,
                  left: 16,
                  right: 16,
                ),
                child: Column(
                  children: [
                    // Enhanced main booking card
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, (1 - _fadeAnimation.value) * 30),
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0A0E27),
                                    Color(0xFF14213D),
                                    Color(0xFF4B6EAF),
                                  ],
                                  stops: [0.0, 0.4, 1.0],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4B6EAF,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                    spreadRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Header
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.directions_bus_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Book Your Journey",
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "Safe and comfortable travel",
                                              style: GoogleFonts.poppins(
                                                color: Colors.white.withValues(
                                                  alpha: 0.8,
                                                ),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 30),

                                  // Route Selection
                                  _buildSelectionTile(
                                    label: "Select Route",
                                    icon: Icons.route,
                                    value:
                                        _selectedRoute ?? "Choose your route",
                                    onTap: () => _showRouteSelectionSheet(),
                                    isLoading: false,
                                  ),

                                  const SizedBox(height: 20),

                                  // From Location
                                  _buildSelectionTile(
                                    label: "From",
                                    icon: Icons.my_location,
                                    value:
                                        _selectedFromStop?.name ??
                                        "Select pickup location",
                                    onTap:
                                        _selectedRoute != null && !_loadingStops
                                            ? () => _showPickupSelection()
                                            : null,
                                    isLoading: _loadingStops,
                                    fallbackController: fromController,
                                    fallbackHint: "Enter pickup location",
                                  ),

                                  const SizedBox(height: 20),

                                  _buildSelectionTile(
                                    label: "To",
                                    icon: Icons.location_on,
                                    value:
                                        _selectedToStop?.name ??
                                        "Select destination",
                                    onTap:
                                        _selectedRoute != null && !_loadingStops
                                            ? () => _showDestinationSelection()
                                            : null,
                                    isLoading: _loadingStops,
                                    fallbackController: toController,
                                    fallbackHint: "Enter destination",
                                  ),

                                  const SizedBox(height: 20),

                                  // Number of Tickets
                                  _buildEnhancedTextField(
                                    controller: ticketController,
                                    label: "Number of Tickets",
                                    icon: Icons.confirmation_number,
                                    hint: "Enter ticket count (max 4)",
                                    keyboardType: TextInputType.number,
                                  ),

                                  const SizedBox(height: 30),

                                  // Confirm Button
                                  Container(
                                    width: double.infinity,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(
                                          0xFF14213D,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed:
                                          _isLoading ? null : bookTickets,
                                      child:
                                          _isLoading
                                              ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Color(0xFF14213D),
                                                      strokeWidth: 3,
                                                    ),
                                              )
                                              : Text(
                                                "Confirm Booking",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - _fadeAnimation.value) * 60),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: GestureDetector(
                      onTap: () {
                        if (_ticketCount != null &&
                            _totalCost != null &&
                            _bookingId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => Checkout(
                                    totalCost: _totalCost?.toDouble() ?? 0.0,
                                    ticketCount: _ticketCount ?? 0,
                                    bookingId: _bookingId ?? "",
                                  ),
                            ),
                          );
                        } else {
                          _showErrorDialog(
                            "Please confirm your booking first.",
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF14213D), Color(0xFF000000)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(100),
                            topRight: Radius.circular(100),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, -10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.payment,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap Here to Pay',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to route selection screen
  void _showRouteSelectionSheet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => RouteSelectionScreen(selectedRoute: _selectedRoute),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final selectedRoute = result['route'] as String?;
      final selectedBusStop = result['busStop'] as BusStop?;

      if (selectedRoute != null) {
        setState(() {
          _selectedRoute = selectedRoute;
          _selectedFromStop = selectedBusStop;
          _selectedToStop = null;
        });

        // Update text controllers if a bus stop was selected
        if (selectedBusStop != null) {
          fromController.text = selectedBusStop.name;
        }
      }
    }
  }

  // Navigate to destination selection screen
  void _showDestinationSelection() async {
    if (_selectedRoute == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DestinationSelectionScreen(
              routeId: _selectedRoute!,
              fromStop: _selectedFromStop,
              selectedDestination: _selectedToStop,
            ),
      ),
    );

    if (result != null && result is BusStop) {
      setState(() {
        _selectedToStop = result;
        toController.text = result.name;
      });
    }
  }

  // Navigate to pickup selection screen
  void _showPickupSelection() async {
    if (_selectedRoute == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PickupSelectionScreen(
              routeId: _selectedRoute!,
              selectedPickup: _selectedFromStop,
            ),
      ),
    );

    if (result != null && result is BusStop) {
      setState(() {
        _selectedFromStop = result;
        fromController.text = result.name;
      });
    }
  }

  // Selection tile widget
  Widget _buildSelectionTile({
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback? onTap,
    bool isLoading = false,
    TextEditingController? fallbackController,
    String? fallbackHint,
  }) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(width: 12),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Loading...",
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Show text field as fallback when no items available
    if (onTap == null && fallbackController != null) {
      return _buildEnhancedTextField(
        controller: fallbackController,
        label: label,
        icon: icon,
        hint: fallbackHint ?? "Enter $label",
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white.withValues(alpha: 0.7),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced text field widget
  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.15),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelText: label,
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.6),
          ),
          labelStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}
