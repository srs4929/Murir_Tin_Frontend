import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SOS extends StatefulWidget {
  const SOS({super.key});

  @override
  State<SOS> createState() => _SOSWidgetState();
}

class _SOSWidgetState extends State<SOS> {
  Timer? _timer;
  int _countdown = 6; // Countdown seconds
  bool _isHolding = false;

  void _startSOSCountdown() {
    _isHolding = true;
    _countdown = 6;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isHolding) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
      });
      if (_countdown == 0) {
        timer.cancel();
        _triggerSOS();
      }
    });
  }

  void _cancelSOSCountdown() {
    _isHolding = false;
    _timer?.cancel();
    setState(() {
      _countdown = 6;
    });
  }

  Future<void> _triggerSOS() async {
    const emergencyNumber = 'tel:999';
    if (await canLaunchUrl(Uri.parse(emergencyNumber))) {
      await launchUrl(
        Uri.parse(emergencyNumber),
        mode: LaunchMode.externalApplication,
      );
    } else {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Could not launch phone call.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF14213D), Color(0xFF4B6EAF)],
            stops: [0.0, 0.57],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isHolding) ...[
                Text(
                  '$_countdown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              GestureDetector(
                onLongPressStart: (_) => _startSOSCountdown(),
                onLongPressEnd: (_) => _cancelSOSCountdown(),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'SOS',
                    style: TextStyle(
                      color: Color.fromARGB(255, 3, 39, 68),
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              Text(
                "Press the button for 5 seconds,\n We will connect you to \nthe nearest emergency center. ",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
