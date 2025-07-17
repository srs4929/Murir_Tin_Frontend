import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:murir_tin/api.dart';
import 'package:murir_tin/utils/beautiful_alerts.dart';

class SocialIssuesScreen extends StatefulWidget {
  const SocialIssuesScreen({super.key});

  @override
  State<SocialIssuesScreen> createState() => _SocialIssuesScreenState();
}

class _SocialIssuesScreenState extends State<SocialIssuesScreen>
    with TickerProviderStateMixin {
  final storage = FlutterSecureStorage();
  final _searchController = TextEditingController();
  late TabController _tabController;

  List<Map<String, dynamic>> complaints = [];
  List<Map<String, dynamic>> _myComplaints = [];
  List<Map<String, dynamic>> _filteredComplaints = [];
  List<Map<String, dynamic>> _filteredMyComplaints = [];
  bool _isLoading = true;

  // Filter states
  Set<String> _selectedFilters = {};
  final List<String> _filterOptions = ['submitted', 'accepted', 'solved'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchComplaints();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    // Start with base data or searched data
    List<Map<String, dynamic>> baseComplaints = complaints;
    List<Map<String, dynamic>> baseMyComplaints = _myComplaints;

    // Apply search if there's a query
    final query = _searchController.text;
    if (query.isNotEmpty) {
      baseComplaints =
          complaints.where((complaint) {
            final title = complaint['title']?.toString().toLowerCase() ?? '';
            final details =
                complaint['details']?.toString().toLowerCase() ?? '';
            final category =
                complaint['category']?.toString().toLowerCase() ?? '';
            final searchQuery = query.toLowerCase();

            return title.contains(searchQuery) ||
                details.contains(searchQuery) ||
                category.contains(searchQuery);
          }).toList();

      baseMyComplaints =
          _myComplaints.where((complaint) {
            final title = complaint['title']?.toString().toLowerCase() ?? '';
            final details =
                complaint['details']?.toString().toLowerCase() ?? '';
            final category =
                complaint['category']?.toString().toLowerCase() ?? '';
            final searchQuery = query.toLowerCase();

            return title.contains(searchQuery) ||
                details.contains(searchQuery) ||
                category.contains(searchQuery);
          }).toList();
    }

    setState(() {
      if (_selectedFilters.isEmpty) {
        _filteredComplaints = List.from(baseComplaints);
        _filteredMyComplaints = List.from(baseMyComplaints);
      } else {
        _filteredComplaints =
            baseComplaints.where((complaint) {
              final status =
                  complaint['status']?.toString().toLowerCase() ?? 'open';
              return _selectedFilters.any((filter) {
                switch (filter) {
                  case 'submitted':
                    return status == 'open' || status == 'submitted';
                  case 'accepted':
                    return status == 'in_progress' ||
                        status == 'investigating' ||
                        status == 'accepted';
                  case 'solved':
                    return status == 'resolved' ||
                        status == 'closed' ||
                        status == 'solved';
                  default:
                    return false;
                }
              });
            }).toList();

        _filteredMyComplaints =
            baseMyComplaints.where((complaint) {
              final status =
                  complaint['status']?.toString().toLowerCase() ?? 'open';
              return _selectedFilters.any((filter) {
                switch (filter) {
                  case 'submitted':
                    return status == 'open' || status == 'submitted';
                  case 'accepted':
                    return status == 'in_progress' ||
                        status == 'investigating' ||
                        status == 'accepted';
                  case 'solved':
                    return status == 'resolved' ||
                        status == 'closed' ||
                        status == 'solved';
                  default:
                    return false;
                }
              });
            }).toList();
      }

      // Sort by recent
      _filteredComplaints.sort(
        (a, b) => b['createdAt'].compareTo(a['createdAt']),
      );
      _filteredMyComplaints.sort(
        (a, b) => b['createdAt'].compareTo(a['createdAt']),
      );
    });
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
      _applyFilters();
    });
  }

  Future<void> fetchComplaints() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await storage.read(key: "jwt_token");
      if (token == null) {
        throw Exception("No JWT token found");
      }

      final response = await http.get(
        Uri.parse(complaints_with_likes_endpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        complaints =
            data.map((item) {
              DateTime createdAt = DateTime.parse(item['created_at']);
              return {
                "id": item['id'] ?? '',
                "date":
                    "${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}",
                "title": item['title'] ?? 'No Title',
                "time":
                    "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')} ${createdAt.hour < 12 ? 'AM' : 'PM'}",
                "details": item['description'] ?? 'No description available',
                "category": _categorizeComplaint(item['title'] ?? ''),
                "likes": item['like_count'] ?? 0,
                "dislikes": item['dislike_count'] ?? 0,
                "hasLiked": item['user_reaction'] == true,
                "hasDisliked": item['user_reaction'] == false,
                "createdAt": createdAt,
                "author": 'Anonymous',
                "status": item['status'] ?? 'Open',
              };
            }).toList();

        setState(() {
          _isLoading = false;
        });
        _filteredComplaints = List.from(complaints);
        await fetchMyComplaints();
      } else {
        throw Exception("Failed to fetch complaints: ${response.statusCode}");
      }
    } catch (e) {
      // print("Error fetching complaints: $e");
      setState(() {
        complaints = [];
        _isLoading = false;
      });

      if (mounted) {
        BeautifulAlerts.showErrorSnackBar(
          context,
          "Failed to load community issues. Please check your connection and try again.",
        );
      }
    }
  }

  Future<void> fetchMyComplaints() async {
    try {
      final token = await storage.read(key: "jwt_token");
      if (token == null) return;

      final response = await http.get(
        Uri.parse(complaint_status_endpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _myComplaints =
              data.map((item) {
                DateTime createdAt = DateTime.parse(item['created_at']);
                return {
                  "id": item['id'] ?? '',
                  "date":
                      "${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}",
                  "title": item['title'] ?? 'No Title',
                  "time":
                      "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')} ${createdAt.hour < 12 ? 'AM' : 'PM'}",
                  "details": item['description'] ?? 'No description available',
                  "category": _categorizeComplaint(item['title'] ?? ''),
                  "likes": 0, // User's own complaints don't show likes
                  "dislikes": 0,
                  "hasLiked": false,
                  "hasDisliked": false,
                  "createdAt": createdAt,
                  "author": 'You', // Mark as user's own
                  "status": item['status'] ?? 'Open',
                };
              }).toList();
          _filteredMyComplaints = List.from(_myComplaints);
        });
      }
    } catch (e) {
      print("Error fetching my complaints: $e");

      // Show beautiful error snackbar for user's complaints
      BeautifulAlerts.showErrorSnackBar(
        context,
        "Unable to load your issues. Please try refreshing.",
      );
    }
  }

  String _categorizeComplaint(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('bus') || titleLower.contains('service')) {
      return 'Bus Service';
    }
    if (titleLower.contains('route') || titleLower.contains('road')) {
      return 'Route Issues';
    }
    if (titleLower.contains('driver') || titleLower.contains('behavior')) {
      return 'Driver Behavior';
    }
    if (titleLower.contains('time') ||
        titleLower.contains('delay') ||
        titleLower.contains('late')) {
      return 'Timing';
    }
    if (titleLower.contains('safe') || titleLower.contains('accident')) {
      return 'Safety';
    }
    if (titleLower.contains('fare') ||
        titleLower.contains('price') ||
        titleLower.contains('money')) {
      return 'Fare Issues';
    }
    return 'Others';
  }

  void _searchComplaints(String query) {
    setState(() {
      if (query.isEmpty) {
        // If no search query, just apply filters
        _applyFilters();
      } else {
        // Apply search to the base data, then apply filters
        List<Map<String, dynamic>> searchedComplaints =
            complaints.where((complaint) {
              final title = complaint['title']?.toString().toLowerCase() ?? '';
              final details =
                  complaint['details']?.toString().toLowerCase() ?? '';
              final category =
                  complaint['category']?.toString().toLowerCase() ?? '';
              final searchQuery = query.toLowerCase();

              return title.contains(searchQuery) ||
                  details.contains(searchQuery) ||
                  category.contains(searchQuery);
            }).toList();

        List<Map<String, dynamic>> searchedMyComplaints =
            _myComplaints.where((complaint) {
              final title = complaint['title']?.toString().toLowerCase() ?? '';
              final details =
                  complaint['details']?.toString().toLowerCase() ?? '';
              final category =
                  complaint['category']?.toString().toLowerCase() ?? '';
              final searchQuery = query.toLowerCase();

              return title.contains(searchQuery) ||
                  details.contains(searchQuery) ||
                  category.contains(searchQuery);
            }).toList();

        // Apply filters to searched results
        if (_selectedFilters.isEmpty) {
          _filteredComplaints = searchedComplaints;
          _filteredMyComplaints = searchedMyComplaints;
        } else {
          _filteredComplaints =
              searchedComplaints.where((complaint) {
                final status =
                    complaint['status']?.toString().toLowerCase() ?? 'open';
                return _selectedFilters.any((filter) {
                  switch (filter) {
                    case 'submitted':
                      return status == 'open' || status == 'submitted';
                    case 'accepted':
                      return status == 'in_progress' ||
                          status == 'investigating' ||
                          status == 'accepted';
                    case 'solved':
                      return status == 'resolved' ||
                          status == 'closed' ||
                          status == 'solved';
                    default:
                      return false;
                  }
                });
              }).toList();

          _filteredMyComplaints =
              searchedMyComplaints.where((complaint) {
                final status =
                    complaint['status']?.toString().toLowerCase() ?? 'open';
                return _selectedFilters.any((filter) {
                  switch (filter) {
                    case 'submitted':
                      return status == 'open' || status == 'submitted';
                    case 'accepted':
                      return status == 'in_progress' ||
                          status == 'investigating' ||
                          status == 'accepted';
                    case 'solved':
                      return status == 'resolved' ||
                          status == 'closed' ||
                          status == 'solved';
                    default:
                      return false;
                  }
                });
              }).toList();
        }
      }

      // Sort by recent
      _filteredComplaints.sort(
        (a, b) => b['createdAt'].compareTo(a['createdAt']),
      );
      _filteredMyComplaints.sort(
        (a, b) => b['createdAt'].compareTo(a['createdAt']),
      );
    });
  }

  Future<void> _toggleLike(String complaintId) async {
    try {
      final token = await storage.read(key: "jwt_token");
      if (token == null) {
        BeautifulAlerts.showErrorSnackBar(
          context,
          "Please log in to react to issues",
        );
        return;
      }

      final response = await http.post(
        Uri.parse('$complaint_like_endpoint/$complaintId/like'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _updateComplaintReaction(complaintId, data);

        // Show beautiful success snackbar
        final complaint = complaints.firstWhere(
          (c) => c['id'].toString() == complaintId,
        );
        final isLiked = complaint['hasLiked'] ?? false;

        BeautifulAlerts.showSuccessSnackBar(
          context,
          isLiked ? "You liked this issue" : "Like removed",
        );
      } else {
        BeautifulAlerts.showErrorSnackBar(
          context,
          "Failed to update your reaction. Please try again.",
        );
      }
    } catch (e) {
      print("Error toggling like: $e");
      BeautifulAlerts.showErrorSnackBar(
        context,
        "Something went wrong. Please check your connection.",
      );
    }
  }

  Future<void> _toggleDislike(String complaintId) async {
    try {
      final token = await storage.read(key: "jwt_token");
      if (token == null) {
        BeautifulAlerts.showErrorSnackBar(
          context,
          "Please log in to react to issues",
        );
        return;
      }

      final response = await http.post(
        Uri.parse('$complaint_dislike_endpoint/$complaintId/dislike'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _updateComplaintReaction(complaintId, data);

        // Show beautiful warning snackbar for dislike
        final complaint = complaints.firstWhere(
          (c) => c['id'].toString() == complaintId,
        );
        final isDisliked = complaint['hasDisliked'] ?? false;

        BeautifulAlerts.showWarningSnackBar(
          context,
          isDisliked ? "You disliked this issue" : "Dislike removed",
        );
      } else {
        BeautifulAlerts.showErrorSnackBar(
          context,
          "Failed to update your reaction. Please try again.",
        );
      }
    } catch (e) {
      print("Error toggling dislike: $e");
      BeautifulAlerts.showErrorSnackBar(
        context,
        "Something went wrong. Please check your connection.",
      );
    }
  }

  void _updateComplaintReaction(String complaintId, Map<String, dynamic> data) {
    setState(() {
      // Update main complaints list
      for (var complaint in complaints) {
        if (complaint['id'].toString() == complaintId) {
          complaint['likes'] = data['like_count'] ?? 0;
          complaint['dislikes'] = data['dislike_count'] ?? 0;
          complaint['hasLiked'] = data['user_reaction'] == true;
          complaint['hasDisliked'] = data['user_reaction'] == false;
          break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final middleBlueColor = Color(0xFF2A3F5F);
    final darkBlueColor = Color(0xFF14213D);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF14213D),
        foregroundColor: Colors.white,
        title: Text(
          'Social Issues',
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
              tooltip: 'Refresh Issues',
              onPressed: _refreshComplaints,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.forum_rounded, color: Colors.white),
              tooltip: 'Community Hub',
              onPressed: () {
                BeautifulAlerts.showInfoSnackBar(
                  context,
                  "Community features coming soon!",
                );
              },
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        middleBlueColor,
                      ),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading community issues...',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: darkBlueColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Header with stats
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [darkBlueColor, middleBlueColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.forum, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Community Issues',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${_filteredComplaints.length} issues shown',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.forum,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Active',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _searchComplaints,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: darkBlueColor,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Search issues by title, category or details...',
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
                              prefixIcon: Icon(
                                Icons.search,
                                color: middleBlueColor,
                                size: 20,
                              ),
                              suffixIcon:
                                  _searchController.text.isNotEmpty
                                      ? IconButton(
                                        onPressed: () {
                                          _searchController.clear();
                                          _searchComplaints('');
                                        },
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.grey.shade600,
                                          size: 20,
                                        ),
                                      )
                                      : null,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        // Filter Chips
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_alt_outlined,
                                color: Colors.white.withOpacity(0.9),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Filter by:',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children:
                                        _filterOptions.map((filter) {
                                          final isSelected = _selectedFilters
                                              .contains(filter);
                                          return Container(
                                            margin: EdgeInsets.only(right: 8),
                                            child: FilterChip(
                                              label: Text(
                                                filter.toUpperCase(),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      isSelected
                                                          ? Colors.white
                                                          : Colors.black,
                                                ),
                                              ),
                                              selected: isSelected,
                                              onSelected:
                                                  (selected) =>
                                                      _toggleFilter(filter),
                                              selectedColor: middleBlueColor,
                                              backgroundColor:
                                                  isSelected
                                                      ? Colors.white
                                                          .withOpacity(0.15)
                                                      : Colors.white
                                                          .withOpacity(0.9),
                                              checkmarkColor: Colors.white,
                                              side: BorderSide(
                                                color:
                                                    isSelected
                                                        ? middleBlueColor
                                                        : Colors.white
                                                            .withOpacity(0.7),
                                                width: 1,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab Bar
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: middleBlueColor,
                      unselectedLabelColor: Colors.grey.shade600,
                      indicatorColor: middleBlueColor,
                      indicatorWeight: 3,
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: [
                        Tab(text: 'Community Issues'),
                        Tab(text: 'My Issues'),
                      ],
                    ),
                  ),

                  // Tab Bar View
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Community Issues Tab
                        _buildIssuesList(_filteredComplaints, middleBlueColor),
                        // My Issues Tab
                        _buildMyIssuesList(
                          _filteredMyComplaints,
                          middleBlueColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Future<void> _refreshComplaints() async {
    try {
      await fetchComplaints();
      BeautifulAlerts.showSuccessSnackBar(
        context,
        "Issues refreshed successfully!",
      );
    } catch (e) {
      // Error already handled in fetchComplaints
    }
  }

  Widget _buildIssuesList(
    List<Map<String, dynamic>> issuesList,
    Color primaryColor,
  ) {
    if (issuesList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              "No issues found",
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Be the first to report a community issue",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshComplaints,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: issuesList.length,
        itemBuilder: (context, index) {
          return EnhancedComplaintCard(
            complaint: issuesList[index],
            primaryColor: primaryColor,
            onLikePressed: () {
              _toggleLike(issuesList[index]['id'].toString());
            },
            onDislikePressed: () {
              _toggleDislike(issuesList[index]['id'].toString());
            },
          );
        },
      ),
    );
  }

  Widget _buildMyIssuesList(
    List<Map<String, dynamic>> issuesList,
    Color primaryColor,
  ) {
    if (issuesList.isEmpty) {
      return Center(
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
              "No issues submitted yet",
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Submit your first complaint to see it here",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshComplaints,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: issuesList.length,
        itemBuilder: (context, index) {
          return MyComplaintCard(
            complaint: issuesList[index],
            primaryColor: primaryColor,
          );
        },
      ),
    );
  }
}

// ---------------- My Complaint Card Widget (without like/dislike) ----------------

class MyComplaintCard extends StatefulWidget {
  final Map<String, dynamic> complaint;
  final Color primaryColor;

  const MyComplaintCard({
    required this.complaint,
    required this.primaryColor,
    Key? key,
  }) : super(key: key);

  @override
  _MyComplaintCardState createState() => _MyComplaintCardState();
}

class _MyComplaintCardState extends State<MyComplaintCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
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

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withOpacity(0.1),
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
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  children: [
                    // Avatar
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.primaryColor,
                            widget.primaryColor.withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    // User info and category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'You',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF14213D),
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.complaint['category'] ?? 'General',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                    color: widget.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${widget.complaint['date']} • ${widget.complaint['time']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Title
                Text(
                  widget.complaint['title'] ?? 'No Title',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF14213D),
                    height: 1.3,
                  ),
                ),

                SizedBox(height: 12),

                // Description
                Text(
                  _isExpanded
                      ? widget.complaint['details'] ?? 'No description'
                      : (widget.complaint['details']?.length ?? 0) > 100
                      ? '${widget.complaint['details']?.substring(0, 100)}...'
                      : widget.complaint['details'] ?? 'No description',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Color(0xFF14213D),
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),

                // See more/less button
                if ((widget.complaint['details']?.length ?? 0) > 100)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        _isExpanded ? "Show Less" : "See More",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: widget.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: 16),

                // Status indicator only (no like/dislike for own complaints)
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          widget.complaint['status'],
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(
                            widget.complaint['status'],
                          ).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                widget.complaint['status'],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            widget.complaint['status'] ?? 'Open',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(
                                widget.complaint['status'],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    // My complaint indicator
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: widget.primaryColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'My Issue',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'resolved':
      case 'closed':
        return Colors.green;
      case 'in_progress':
      case 'investigating':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

// ---------------- ComplaintBox Widget ----------------

class ComplaintBox extends StatefulWidget {
  final String date;
  final String title;
  final String time;
  final String details;
  final int likes;
  final Color middleBlueColor;
  final VoidCallback onLikePressed;

  const ComplaintBox({
    required this.date,
    required this.title,
    required this.time,
    required this.details,
    required this.likes,
    required this.middleBlueColor,
    required this.onLikePressed,
  });

  @override
  _ComplaintBoxState createState() => _ComplaintBoxState();
}

class _ComplaintBoxState extends State<ComplaintBox> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    'https://www.w3schools.com/w3images/avatar2.png',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: widget.middleBlueColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  widget.date,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  widget.time,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              _isExpanded
                  ? widget.details
                  : widget.details.length > 60
                  ? '${widget.details.substring(0, 60)}.....'
                  : widget.details,
              style: GoogleFonts.poppins(fontSize: 15),
            ),
            const SizedBox(height: 10),

            if (widget.details.length > 60)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Text(
                  _isExpanded ? "Show Less" : "See more",
                  style: TextStyle(fontSize: 16, color: widget.middleBlueColor),
                ),
              ),

            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: widget.onLikePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.middleBlueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.thumb_up, color: Colors.white, size: 20),
                    const SizedBox(width: 5),
                    Text(
                      "(${widget.likes})",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Enhanced Complaint Card Widget ----------------

class EnhancedComplaintCard extends StatefulWidget {
  final Map<String, dynamic> complaint;
  final Color primaryColor;
  final VoidCallback onLikePressed;
  final VoidCallback onDislikePressed;

  const EnhancedComplaintCard({
    required this.complaint,
    required this.primaryColor,
    required this.onLikePressed,
    required this.onDislikePressed,
    Key? key,
  }) : super(key: key);

  @override
  _EnhancedComplaintCardState createState() => _EnhancedComplaintCardState();
}

class _EnhancedComplaintCardState extends State<EnhancedComplaintCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
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

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  children: [
                    // Avatar
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.primaryColor,
                            widget.primaryColor.withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    // User info and category
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.complaint['author'] ?? 'Anonymous',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF14213D),
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.complaint['category'] ?? 'General',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                    color: widget.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${widget.complaint['date']} • ${widget.complaint['time']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Title
                Text(
                  widget.complaint['title'] ?? 'No Title',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF14213D),
                    height: 1.3,
                  ),
                ),

                SizedBox(height: 12),

                // Description
                Text(
                  _isExpanded
                      ? widget.complaint['details'] ?? 'No description'
                      : (widget.complaint['details']?.length ?? 0) > 100
                      ? '${widget.complaint['details']?.substring(0, 100)}...'
                      : widget.complaint['details'] ?? 'No description',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Color(0xFF14213D),
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),

                // See more/less button
                if ((widget.complaint['details']?.length ?? 0) > 100)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        _isExpanded ? "Show Less" : "See More",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: widget.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: 16),

                // Status and action buttons
                Row(
                  children: [
                    // Status indicator
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          widget.complaint['status'],
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(
                            widget.complaint['status'],
                          ).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                widget.complaint['status'],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            widget.complaint['status'] ?? 'Open',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(
                                widget.complaint['status'],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    // Like button
                    Container(
                      decoration: BoxDecoration(
                        color:
                            widget.complaint['hasLiked']
                                ? Colors.green.withOpacity(0.15)
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              widget.complaint['hasLiked']
                                  ? Colors.green.withOpacity(0.4)
                                  : Colors.grey.shade300,
                          width: widget.complaint['hasLiked'] ? 2 : 1,
                        ),
                        boxShadow:
                            widget.complaint['hasLiked']
                                ? [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                                : null,
                      ),
                      child: InkWell(
                        onTap: widget.onLikePressed,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.complaint['hasLiked']
                                    ? Icons.thumb_up
                                    : Icons.thumb_up_outlined,
                                color:
                                    widget.complaint['hasLiked']
                                        ? Colors.green.shade600
                                        : Colors.grey.shade600,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '${widget.complaint['likes'] ?? 0}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      widget.complaint['hasLiked']
                                          ? Colors.green.shade700
                                          : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    // Dislike button
                    Container(
                      decoration: BoxDecoration(
                        color:
                            widget.complaint['hasDisliked']
                                ? Colors.red.withOpacity(0.15)
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              widget.complaint['hasDisliked']
                                  ? Colors.red.withOpacity(0.4)
                                  : Colors.grey.shade300,
                          width: widget.complaint['hasDisliked'] ? 2 : 1,
                        ),
                        boxShadow:
                            widget.complaint['hasDisliked']
                                ? [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                                : null,
                      ),
                      child: InkWell(
                        onTap: widget.onDislikePressed,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.complaint['hasDisliked']
                                    ? Icons.thumb_down
                                    : Icons.thumb_down_outlined,
                                color:
                                    widget.complaint['hasDisliked']
                                        ? Colors.red.shade600
                                        : Colors.grey.shade600,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '${widget.complaint['dislikes'] ?? 0}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      widget.complaint['hasDisliked']
                                          ? Colors.red.shade700
                                          : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'resolved':
      case 'closed':
        return Colors.green;
      case 'in_progress':
      case 'investigating':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
