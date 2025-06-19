import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:murir_tin/Component.dart';

class Livemap extends StatefulWidget {
  const Livemap({super.key});

  @override
  State<Livemap> createState() => _Livemapstate();
}

class _Livemapstate extends State<Livemap> {
  final Completer<GoogleMapController> mapController = Completer();
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const GAppBar(title: "Live Map"),
    body:GoogleMap(initialCameraPosition:
    CameraPosition(target: LatLng(23.8103, 90.4125),zoom:12))
    );
  }
}
