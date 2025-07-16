import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class Livemap extends StatefulWidget {
  const Livemap({super.key});

  @override
  State<Livemap> createState() => _LivemapState();
}

class _LivemapState extends State<Livemap> {
  String _locationMessage = "Fetching location...";
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
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


      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, 
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
      String address =
          "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";


      setState(() {
        _locationMessage =
            "Latitude: ${position.latitude}\nLongitude: ${position.longitude}\nAddress: $address";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationMessage =
            "Latitude: ${position.latitude}\nLongitude: ${position.longitude}\nAddress: Unable to fetch address";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Location"),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMessage != null
                ? Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _locationMessage,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
      ),
    );
  }
}