import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:murir_tin/Component.dart';
import 'package:murir_tin/api.dart';
import 'package:murir_tin/StatusScreen.dart';
import 'package:murir_tin/Providers/user_provider.dart';

class ComplaintStatusScreen extends ConsumerStatefulWidget {
  final String? username;
  final String? email;
  final String? profilePicUrl;

  const ComplaintStatusScreen({
    super.key,
    this.username,
    this.email,
    this.profilePicUrl,
  });

  @override
  ConsumerState<ComplaintStatusScreen> createState() =>
      _ComplaintStatusScreenState();
}

class _ComplaintStatusScreenState extends ConsumerState<ComplaintStatusScreen> {
  final _storage = FlutterSecureStorage();
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, String>> complaints = [];
  List<Map<String, String>> filteredComplaints = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUserComplaints();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).loadUser();
    });
  }

  Future<void> _fetchUserComplaints() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception("Token not found");

      final response = await http.get(
        Uri.parse(complaint_status_endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          complaints =
              data.map<Map<String, String>>((item) {
                final createdAt = DateTime.parse(item['created_at']);
                return {
                  'id': item['id'].toString(),
                  'title': item['title'],
                  'date':
                      "${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}",
                  'time':
                      "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')} ${createdAt.hour < 12 ? 'AM' : 'PM'}",
                  'status': item['status'] ?? 'Unknown',
                };
              }).toList();
          filteredComplaints = complaints; // Initialize filtered list
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load complaints');
      }
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterComplaints(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        filteredComplaints = complaints;
      } else {
        filteredComplaints =
            complaints.where((complaint) {
              final title = complaint['title']?.toLowerCase() ?? '';
              final status = complaint['status']?.toLowerCase() ?? '';
              final date = complaint['date']?.toLowerCase() ?? '';
              final searchLower = query.toLowerCase();

              return title.contains(searchLower) ||
                  status.contains(searchLower) ||
                  date.contains(searchLower);
            }).toList();
      }
    });
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
      case 'in progress':
        return Colors.blue;
      case 'resolved':
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
      case 'in progress':
        return 'In Progress';
      case 'resolved':
      case 'completed':
        return 'Resolved';
      case 'rejected':
      case 'cancelled':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final middleBlueColor = Color(0xFF2F4F78);

    return Scaffold(
      appBar: GAppBar(title: "Complain Status"),

      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: middleBlueColor))
              : Column(
                children: [
                  // Search Bar Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade50, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade100,
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterComplaints,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Color(0xFF14213D),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Search complaints by title, status or date...',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          prefixIcon: Container(
                            margin: EdgeInsets.all(12),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: middleBlueColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.search_rounded,
                              color: middleBlueColor,
                              size: 18,
                            ),
                          ),
                          suffixIcon:
                              _searchQuery.isNotEmpty
                                  ? IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterComplaints('');
                                    },
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color: Colors.grey.shade600,
                                      size: 20,
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                    ),
                  ),

                  // Results count and filter info
                  if (filteredComplaints.length != complaints.length)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            color: middleBlueColor,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Showing ${filteredComplaints.length} of ${complaints.length} complaints',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: middleBlueColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Complaints List
                  Expanded(
                    child:
                        complaints.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    "No complaints submitted yet.",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : filteredComplaints.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    "No complaints found matching your search.",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterComplaints('');
                                    },
                                    child: Text(
                                      'Clear search',
                                      style: GoogleFonts.poppins(
                                        color: middleBlueColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: filteredComplaints.length,
                              itemBuilder: (context, index) {
                                final complaint = filteredComplaints[index];
                                return Container(
                                  margin: EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade300,
                                        blurRadius: 15,
                                        offset: Offset(0, 5),
                                        spreadRadius: 1,
                                      ),
                                      BoxShadow(
                                        color: Colors.white,
                                        blurRadius: 8,
                                        offset: Offset(0, -2),
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white,
                                            Colors.grey.shade50,
                                            Colors.white,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          stops: [0.0, 0.5, 1.0],
                                        ),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          // Header Section with gradient
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF14213D),
                                                  const Color(0xFF4B6EAF),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(
                                                      20,
                                                    ),
                                                    topRight: Radius.circular(
                                                      20,
                                                    ),
                                                  ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          15,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.support_agent_rounded,
                                                    color: Colors.white,
                                                    size: 28,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Support Ticket',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    0.9,
                                                                  ),
                                                              letterSpacing:
                                                                  0.5,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        complaint['title']!,
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 18,
                                                              color:
                                                                  Colors.white,
                                                              height: 1.2,
                                                            ),
                                                        maxLines: 2,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                      complaint['status'],
                                                    ).withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          15,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    _getStatusText(
                                                      complaint['status'],
                                                    ),
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // User Information Section
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.blue.shade50
                                                      .withOpacity(0.15),
                                                  Colors.white.withOpacity(0.9),
                                                  Colors.blue.shade50
                                                      .withOpacity(0.1),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                stops: [0.0, 0.5, 1.0],
                                              ),
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey.shade200,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF4B6EAF,
                                                    ).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons
                                                        .person_outline_rounded,
                                                    color: const Color(
                                                      0xFF4B6EAF,
                                                    ),
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Submitted by',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color:
                                                                  Colors
                                                                      .grey
                                                                      .shade600,
                                                              letterSpacing:
                                                                  0.3,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Consumer(
                                                        builder: (
                                                          context,
                                                          ref,
                                                          child,
                                                        ) {
                                                          final userAsync = ref
                                                              .watch(
                                                                userProvider,
                                                              );
                                                          return userAsync.when(
                                                            data:
                                                                (user) => Text(
                                                                  user?.username ??
                                                                      widget
                                                                          .username ??
                                                                      'User',
                                                                  style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: const Color(
                                                                      0xFF14213D,
                                                                    ),
                                                                  ),
                                                                ),
                                                            loading:
                                                                () => Text(
                                                                  widget.username ??
                                                                      'Loading...',
                                                                  style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: const Color(
                                                                      0xFF14213D,
                                                                    ),
                                                                  ),
                                                                ),
                                                            error:
                                                                (
                                                                  error,
                                                                  stack,
                                                                ) => Text(
                                                                  widget.username ??
                                                                      'User',
                                                                  style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: const Color(
                                                                      0xFF14213D,
                                                                    ),
                                                                  ),
                                                                ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Content Section
                                          Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              children: [
                                                // Date and Time Info
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              16,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFF4B6EAF,
                                                          ).withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                15,
                                                              ),
                                                          border: Border.all(
                                                            color: const Color(
                                                              0xFF4B6EAF,
                                                            ).withOpacity(0.2),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .calendar_today_rounded,
                                                              color:
                                                                  const Color(
                                                                    0xFF4B6EAF,
                                                                  ),
                                                              size: 24,
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Text(
                                                              'Date',
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    Colors
                                                                        .grey
                                                                        .shade600,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Text(
                                                              complaint['date']!,
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color:
                                                                    const Color(
                                                                      0xFF14213D,
                                                                    ),
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              16,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFF14213D,
                                                          ).withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                15,
                                                              ),
                                                          border: Border.all(
                                                            color: const Color(
                                                              0xFF14213D,
                                                            ).withOpacity(0.2),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .access_time_rounded,
                                                              color:
                                                                  const Color(
                                                                    0xFF14213D,
                                                                  ),
                                                              size: 24,
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Text(
                                                              'Time',
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    Colors
                                                                        .grey
                                                                        .shade600,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Text(
                                                              complaint['time']!,
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color:
                                                                    const Color(
                                                                      0xFF14213D,
                                                                    ),
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 20),

                                                // Action Button
                                                Container(
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(
                                                          0xFF4B6EAF,
                                                        ).withOpacity(0.3),
                                                        blurRadius: 12,
                                                        offset: const Offset(
                                                          0,
                                                          6,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      final complaintId =
                                                          complaint['id']!;
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (
                                                                context,
                                                              ) => StatusScreen(
                                                                complaintId:
                                                                    complaintId,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                            0xFF4B6EAF,
                                                          ),
                                                      foregroundColor:
                                                          Colors.white,
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 16,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .visibility_rounded,
                                                          size: 22,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Text(
                                                          'View Details & Status',
                                                          style:
                                                              GoogleFonts.poppins(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 16,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                letterSpacing:
                                                                    0.5,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
