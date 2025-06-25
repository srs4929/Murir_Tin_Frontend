// import 'package:flutter/material.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

// class BusMap extends StatefulWidget {
//   const BusMap({super.key});

//   @override
//   State<BusMap> createState() => _BusMapState();
// }

// class _BusMapState extends State<BusMap> {
//   MapboxMap? mapboxMap;

//   PointAnnotationManager? pointAnnotationManager;
//   PointAnnotation? pointAnnotation;

//   final Position busStopLocation = Position(90.45041, 23.70287);

//   @override
//   void dispose() {
//     pointAnnotationManager?.deleteAll(); // Cleanup annotations
//     super.dispose();
//   }

//   // PointAnnotationOptions _annotationOptions() {
//   //   return PointAnnotationOptions(
//   //     geometry: Point(coordinates: busStopLocation),
//   //     iconImage: "marker-15",
//   //     iconSize: 1.5,
//   //     textField: "BusStop42", // Optional label
//   //     textOffset: [0, -1.5],
//   //   );
//   // }

//   void _onMapCreated(MapboxMap mapBoxMap) {
//     mapboxMap = mapBoxMap;

//     mapBoxMap.annotations.createPointAnnotationManager().then((manager) {
//       pointAnnotationManager = manager;
//       _createMarker(busStopLocation);
//     });

//     mapBoxMap.easeTo(
//       CameraOptions(center: Point(coordinates: busStopLocation), zoom: 15),
//       MapAnimationOptions(duration: 2000),
//     );
//   }

//   Future<void> _createMarker(Position busStopLocation) async {
//     pointAnnotationManager
//         ?.create(
//           PointAnnotationOptions(
//             geometry: Point(coordinates: busStopLocation),
//             iconImage: "bus",
//             textField: "Sonir Akhra Bus Stop",
//             textColor: 0xFFFFF000.toInt(),
//             iconSize: 2.5,
//             iconOffset: [0.0, -10.0],
//           ),
//         )
//         .then((value) => pointAnnotation = value);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Bus Map')),
//       body: MapWidget(styleUri: MapboxStyles.DARK, onMapCreated: _onMapCreated),
//     );
//   }
// }
