import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

import 'package:murir_tin/Component.dart';
import 'package:murir_tin/api.dart';

class StatusScreen extends StatefulWidget {
  final String complaintId;

  const StatusScreen({super.key, required this.complaintId});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final _secureStorage = FlutterSecureStorage();

  bool isSubmitted = false;
  bool isAccepted = false;
  bool isSolved = false;
  String description = '';
  bool isLoading = true;

  final middleBlueColor = Color(0xFF2F4F78);

  @override
  void initState() {
    super.initState();
    fetchComplaintDetails();

    // Add a safety timeout to prevent infinite loading
    Timer(Duration(seconds: 15), () {
      if (mounted && isLoading) {
        print('⏰ Loading timeout reached, stopping loading state');
        setState(() {
          isLoading = false;
          description =
              'Failed to load complaint details due to timeout. Please try refreshing.';
        });
      }
    });
  }

  Future<void> fetchComplaintDetails() async {
    print('🔄 Fetching complaint details for ID: ${widget.complaintId}');

    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      if (token == null) {
        print('❌ JWT token not found');
        throw Exception("JWT token not found");
      }

      print('🔐 JWT token found, making request...');
      final url = '$complaints_endpoint${widget.complaintId}';
      print('📡 Request URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Request timeout - please check your internet connection',
              );
            },
          );

      print('📊 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Complaint data received: $data');

        setState(() {
          description = data['description'] ?? 'No description available';
          final status = data['status'] ?? 'submitted';
          isSubmitted =
              status == 'submitted' ||
              status == 'accepted' ||
              status == 'solved';
          isAccepted = status == 'accepted' || status == 'solved';
          isSolved = status == 'solved';
          isLoading = false;
        });

        print('✅ State updated successfully');
      } else {
        print('❌ HTTP Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch complaint: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching complaint details: $e');
      setState(() {
        description =
            'Unable to load complaint details. Error: ${e.toString()}';
        isLoading = false;
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load complaint details: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GAppBar(title: "Current Status"),
      floatingActionButton:
          isSolved
              ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF4CAF50).withOpacity(0.25),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              Icons.celebration,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Complaint Resolved Successfully!',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Color(0xFF4CAF50),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  label: Text(
                    'Resolved!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  icon: Icon(
                    Icons.celebration_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body:
          isLoading
              ? Container(
                decoration: BoxDecoration(color: Colors.white),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4B6EAF),
                        ),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Loading Status...',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Color(0xFF14213D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : Container(
                decoration: BoxDecoration(color: Colors.white),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Status Progress Section
                      Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Color(0xFF4B6EAF).withOpacity(0.003),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF14213D).withOpacity(0.05),
                              spreadRadius: 0,
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF14213D),
                                        Color(0xFF4B6EAF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(
                                          0xFF4B6EAF,
                                        ).withOpacity(0.2),
                                        spreadRadius: 0,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.timeline,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Progress Tracker',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF14213D),
                                        ),
                                      ),
                                      Text(
                                        'Step ${_getCurrentStep()} of 3 • ${_getEstimatedTime()}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Color(0xFF4B6EAF),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 18),
                            Row(
                              children: [
                                buildEnhancedStatusItem(
                                  'Submitted',
                                  isSubmitted,
                                  Icons.send_rounded,
                                  0,
                                ),
                                buildEnhancedConnectionLine(
                                  isSubmitted,
                                  isAccepted,
                                ),
                                buildEnhancedStatusItem(
                                  'Accepted',
                                  isAccepted,
                                  Icons.verified_user_rounded,
                                  1,
                                ),
                                buildEnhancedConnectionLine(
                                  isAccepted,
                                  isSolved,
                                ),
                                buildEnhancedStatusItem(
                                  'Solved',
                                  isSolved,
                                  Icons.celebration_rounded,
                                  2,
                                ),
                              ],
                            ),
                            SizedBox(height: 18),
                            // Progress Description with enhanced styling
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF14213D).withOpacity(0.003),
                                    Color(0xFF4B6EAF).withOpacity(0.005),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Color(0xFF4B6EAF).withOpacity(0.15),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF4B6EAF).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      color: Color(0xFF4B6EAF),
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _getStatusMessage(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        color: Color(0xFF14213D),
                                        fontWeight: FontWeight.w500,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Add completion percentage indicator
                            if (_getCurrentStep() > 0) ...[
                              SizedBox(height: 20),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF4CAF50).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.trending_up_rounded,
                                      color: Color(0xFF4CAF50),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '${((_getCurrentStep() / 3) * 100).toInt()}% Complete',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4CAF50),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Complaint Details Section
                      Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Color(0xFF14213D).withOpacity(0.002),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF14213D).withOpacity(0.05),
                              spreadRadius: 0,
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF14213D),
                                        Color(0xFF4B6EAF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(
                                          0xFF4B6EAF,
                                        ).withOpacity(0.2),
                                        spreadRadius: 0,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.article_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Complaint Details',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF14213D),
                                        ),
                                      ),
                                      Text(
                                        'Your submitted complaint information',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Color(0xFF4B6EAF),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFDFDFD),
                                    Color(0xFF4B6EAF).withOpacity(0.002),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(0xFF4B6EAF).withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Color(
                                            0xFF4B6EAF,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.format_quote,
                                          color: Color(0xFF4B6EAF),
                                          size: 14,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Description',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF14213D),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Color(
                                          0xFF4B6EAF,
                                        ).withOpacity(0.05),
                                      ),
                                    ),
                                    child: Text(
                                      description,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        height: 1.5,
                                        color: Color(0xFF14213D),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      // Action Buttons Row
                      Row(
                        children: [
                          // Back Button
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF14213D),
                                    Color(0xFF4B6EAF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF4B6EAF).withOpacity(0.25),
                                    spreadRadius: 0,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_back_ios_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Back to List",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 12),

                          // Refresh Button
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Color(0xFF4B6EAF).withOpacity(0.2),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF14213D).withOpacity(0.08),
                                  spreadRadius: 0,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  isLoading = true;
                                });
                                fetchComplaintDetails();
                              },
                              icon: Icon(
                                Icons.refresh_rounded,
                                color: Color(0xFF4B6EAF),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
    );
  }

  String _getStatusMessage() {
    if (isSolved) {
      return '🎉 Fantastic! Your complaint has been successfully resolved. Thank you for your patience and trust in our service.';
    } else if (isAccepted) {
      return '⚡ Good news! Our dedicated team is actively working on your complaint. We\'ll notify you immediately once it\'s resolved.';
    } else if (isSubmitted) {
      return '📋 Your complaint has been received and is currently under review by our expert team. We appreciate your patience.';
    } else {
      return '� We\'re updating your complaint status. Please check back in a few moments for the latest information.';
    }
  }

  String _getEstimatedTime() {
    if (isSolved) {
      return 'Completed';
    } else if (isAccepted) {
      return 'Est. 2-3 days';
    } else if (isSubmitted) {
      return 'Est. 1-2 days';
    } else {
      return 'Calculating...';
    }
  }

  int _getCurrentStep() {
    if (isSolved) return 3;
    if (isAccepted) return 2;
    if (isSubmitted) return 1;
    return 0;
  }

  Widget buildEnhancedStatusItem(
    String status,
    bool isCompleted,
    IconData icon,
    int step,
  ) {
    Color primaryColor = isCompleted ? Color(0xFF4CAF50) : Color(0xFFE0E0E0);
    Color shadowColor = isCompleted ? Color(0xFF4CAF50) : Color(0xFFBDBDBD);
    Color textColor = isCompleted ? Color(0xFF14213D) : Color(0xFF9E9E9E);

    return Expanded(
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 1200 + (step * 300)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.7 + (0.3 * value),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow effect
                      if (isCompleted) ...[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Color(0xFF4CAF50).withOpacity(0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                      // Main circle
                      AnimatedContainer(
                        duration: Duration(milliseconds: 400),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient:
                              isCompleted
                                  ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF66BB6A),
                                    ],
                                  )
                                  : null,
                          color: isCompleted ? null : primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor.withOpacity(
                                isCompleted ? 0.2 : 0.1,
                              ),
                              spreadRadius: 0,
                              blurRadius: isCompleted ? 8 : 4,
                              offset: Offset(0, isCompleted ? 4 : 2),
                            ),
                          ],
                          border: Border.all(
                            color:
                                isCompleted ? Colors.white : Color(0xFFE0E0E0),
                            width: 2,
                          ),
                        ),
                        child: TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 600),
                          tween: Tween(
                            begin: 0.0,
                            end: isCompleted ? 1.0 : 0.0,
                          ),
                          builder: (context, iconValue, child) {
                            return Transform.scale(
                              scale: 0.8 + (0.2 * iconValue),
                              child: Icon(
                                isCompleted ? Icons.check_rounded : icon,
                                color:
                                    isCompleted
                                        ? Colors.white
                                        : Color(0xFF9E9E9E),
                                size: 18,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    status,
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 11,
                      fontWeight:
                          isCompleted ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient:
                          isCompleted
                              ? LinearGradient(
                                colors: [
                                  Color(0xFF4CAF50).withOpacity(0.15),
                                  Color(0xFF66BB6A).withOpacity(0.15),
                                ],
                              )
                              : null,
                      color:
                          isCompleted
                              ? null
                              : Color(0xFFE0E0E0).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isCompleted
                                ? Color(0xFF4CAF50).withOpacity(0.3)
                                : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.schedule_rounded,
                          size: 8,
                          color:
                              isCompleted
                                  ? Color(0xFF4CAF50)
                                  : Color(0xFF9E9E9E),
                        ),
                        SizedBox(width: 2),
                        Text(
                          isCompleted ? 'Done' : 'Pending',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color:
                                isCompleted
                                    ? Color(0xFF4CAF50)
                                    : Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildEnhancedConnectionLine(bool first, bool second) {
    bool isActive = first && second;

    return Expanded(
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 1500),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Container(
            height: 3,
            margin: EdgeInsets.only(top: 18, left: 8, right: 8),
            child: Stack(
              children: [
                // Background line
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                // Active progress line
                if (isActive) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(1.5),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 800),
                      width: double.infinity,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF4CAF50),
                            Color(0xFF66BB6A),
                            Color(0xFF4CAF50),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF4CAF50).withOpacity(0.15),
                            spreadRadius: 0,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildStatusItem(String status, bool isCompleted, Color color) {
    return Column(
      children: [
        Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? Colors.green : Colors.grey,
          size: 30,
        ),
        SizedBox(height: 8),
        Text(
          status,
          style: TextStyle(
            color: isCompleted ? Colors.green : Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildConnectionLine(
    bool first,
    bool second,
    Color lineColor,
    Color greenColor,
  ) {
    return Expanded(
      child: Container(
        height: 2,
        color: first && second ? greenColor : lineColor,
      ),
    );
  }
}
