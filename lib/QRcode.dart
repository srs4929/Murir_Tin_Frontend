import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pretty_qr_code/pretty_qr_code.dart';


import 'package:murir_tin/Component.dart';
import 'api.dart';


class TicketData {
  final int id;
  final String userId;
  final int routeId;
  final String fromLocation;
  final String toLocation;
  final int ticketCount;
  final int totalCost;

  TicketData({
    required this.id,
    required this.userId,
    required this.routeId,
    required this.fromLocation,
    required this.toLocation,
    required this.ticketCount,
    required this.totalCost,
  });

  factory TicketData.fromJson(Map<String, dynamic> json) {
    return TicketData(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      routeId: json['route_id'] as int,
      fromLocation: json['from_location'] as String,
      toLocation: json['to_location'] as String,
      ticketCount: json['ticket_count'] as int,
      totalCost: json['total_cost'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'route_id': routeId,
      'from_location': fromLocation,
      'to_location': toLocation,
      'ticket_count': ticketCount,
      'total_cost': totalCost,
    };
  }
}



class Qrcode extends StatefulWidget {
  final int ticketCount;
  final String ticketId;

  const Qrcode({
    Key? key,
    required this.ticketCount,
    required this.ticketId,
  }) : super(key: key);

  @override
  State<Qrcode> createState() => _QrcodeState();
}

class _QrcodeState extends State<Qrcode> {
  TicketData? _ticketData;
  String? _errorMessage;
  final _storage = const FlutterSecureStorage();
  bool isloading = true;

  @override
  void initState() {
    super.initState();
    fetchTicketData();
  }

  Future<String?> _getJwtToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      print('DEBUG: JWT Token is null or empty. User might not be logged in.');
    } else {
      print('DEBUG: Retrieved JWT Token: $token');
    }
    return token;
  }

  Future<void> fetchTicketData() async {
    setState(() {
      isloading = true;
      _errorMessage = null;
    });

    final token = await _getJwtToken();

    if (token == null) {
      if (mounted) {
        setState(() {
          isloading = false;
          _errorMessage = "Authentication required. Please log in again.";
        });
      }
      return;
    }

    try {
      int parsedTicketId;
      try {
        parsedTicketId = int.parse(widget.ticketId);
      } catch (e) {
        if (mounted) {
          setState(() {
            isloading = false;
            _errorMessage = "Invalid Ticket ID format.";
          });
        }
        print('DEBUG: Error parsing ticketId: $e');
        return;
      }

      final response = await http.get(
        Uri.parse('$qr_code_endpoint/$parsedTicketId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          _ticketData = TicketData.fromJson(jsonData);
          isloading = false;
        });
        print('DEBUG: Successfully fetched and parsed TicketData.');
      } else {
        String detail = "An unknown error occurred.";
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody != null && errorBody is Map && errorBody.containsKey('detail')) {
            detail = errorBody['detail'];
          }
        } catch (e) {
          print('DEBUG: Could not parse error response body: $e');
        }

        print('DEBUG: Failed to fetch data. Status: ${response.statusCode}, Body: ${response.body}');
        if (mounted) {
          setState(() {
            isloading = false;
            _errorMessage = "Error (${response.statusCode}): $detail";
          });
        }
      }
    } catch (e) {
      print('DEBUG: Exception during ticket fetch: $e');
      if (mounted) {
        setState(() {
          isloading = false;
          _errorMessage = "Network error or unexpected response: ${e.toString()}";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GAppBar(title: "Ticket QR"),
      body: Center(
        child: isloading
            ? const CircularProgressIndicator()
            : _errorMessage != null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchTicketData,
              child: const Text("Retry"),
            ),
          ],
        )
            : _ticketData == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: Colors.blue, size: 50),
            const SizedBox(height: 10),
            Text(
              "No ticket data available.",
              style: GoogleFonts.poppins(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Your Booked Ticket QR",
              style: GoogleFonts.poppins(
                fontSize: 22,
                color: const Color(0xFF14213D),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 250,
              height: 250,
              child: PrettyQrView.data(
                data: "User id: ${_ticketData!.id} \n"
                    "Route id: ${_ticketData!.routeId} \n"
                    "From: ${_ticketData!.fromLocation} \n"
                    "To: ${_ticketData!.toLocation} \n"
                    "Ticket Count: ${_ticketData!.ticketCount} \n"
                    "Total cost: ${_ticketData!.totalCost}",
                errorCorrectLevel: QrErrorCorrectLevel.M,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Scan this QR code for verification",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}