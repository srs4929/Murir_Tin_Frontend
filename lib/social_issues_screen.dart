 import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:murir_tin/api.dart';

class SocialIssuesScreen extends StatefulWidget {
  @override
  _SocialIssuesScreenState createState() => _SocialIssuesScreenState();
}

class _SocialIssuesScreenState extends State<SocialIssuesScreen> {
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> complaints = [];
  List<Map<String, dynamic>> _filteredComplaints = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    try {
      final token = await storage.read(key: "jwt_token");
      if (token == null) {
        throw Exception("No JWT token found");
      }

      final response = await http.get(
        Uri.parse(social_issues_endpoint), // Replace this with your actual API URL
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        complaints = data.map((item) {
          DateTime createdAt = DateTime.parse(item['created_at']);
          return {
            "date":
            "${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}",
            "title": item['title'],
            "time":
            "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')} ${createdAt.hour < 12 ? 'AM' : 'PM'}",
            "details": item['description'],
            "likes": 0,
            "hasLiked": false,
          };
        }).toList();

        setState(() {
          _filteredComplaints = List.from(complaints);
          _sortComplaintsByLikes();
        });
      } else {
        throw Exception("Failed to fetch complaints: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching complaints: $e");
      setState(() {
        complaints = [];
        _filteredComplaints = [];
      });
    }
  }

  void _searchComplaints(String query) {
    final results = complaints.where((complaint) {
      return complaint['title']!.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredComplaints = results;
      _sortComplaintsByLikes();
    });
  }

  void _sortComplaintsByLikes() {
    _filteredComplaints.sort((a, b) => b['likes'].compareTo(a['likes']));
  }

  @override
  Widget build(BuildContext context) {
    final middleBlueColor = Color(0xFF2F4F78);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [middleBlueColor, Color(0xFF14213D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: const Text('Social-issues', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 30),
          onPressed: () {},
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchComplaints,
              decoration: InputDecoration(
                labelText: 'Search by Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _filteredComplaints.isEmpty
                ? Center(child: Text("No complaints found"))
                : ListView.builder(
              itemCount: _filteredComplaints.length,
              itemBuilder: (context, index) {
                return ComplaintBox(
                  date: _filteredComplaints[index]["date"],
                  title: _filteredComplaints[index]["title"],
                  time: _filteredComplaints[index]["time"],
                  details: _filteredComplaints[index]["details"],
                  likes: _filteredComplaints[index]["likes"],
                  middleBlueColor: middleBlueColor,
                  onLikePressed: () {
                    setState(() {
                      if (!_filteredComplaints[index]['hasLiked']) {
                        _filteredComplaints[index]['likes']++;
                        _filteredComplaints[index]['hasLiked'] = true;
                      }
                    });
                    _sortComplaintsByLikes();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
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
                Text(widget.date, style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(widget.time, style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              _isExpanded
                  ? widget.details
                  : widget.details.length > 60
                  ? '${widget.details.substring(0, 60)}.....'
                  : widget.details,
              style: TextStyle(fontSize: 16),
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
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.middleBlueColor,
                  ),
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