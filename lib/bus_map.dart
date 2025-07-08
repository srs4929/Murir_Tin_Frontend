import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:murir_tin/Models/bus_stop.dart';
import 'package:murir_tin/Models/nearest_stop.dart';
import 'package:murir_tin/Services/FindMyBus/get_all_bus_stops.dart';
import 'package:murir_tin/Services/FindMyBus/get_all_routes.dart';
import 'package:murir_tin/Services/FindMyBus/get_nearest_stop.dart';
import 'package:murir_tin/Services/location_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:murir_tin/Services/FindMyBus/stoppage_url_maker.dart';

class BusMap extends StatefulWidget {
  const BusMap({super.key});

  @override
  State<BusMap> createState() => _BusMapState();
}

class _BusMapState extends State<BusMap> {
  mapbox.MapboxMap? mapboxMap;

  mapbox.PointAnnotationManager? pointAnnotationManager;
  List<mapbox.PointAnnotation>? pointAnnotations = [];
  Position? userLocation;
  String routeId = "2";
  List<String> routes = [];
  bool myLocationClicked = false;

  List<BusStop> busStopLocations = [];

  bool isLoading = true;
  bool isMapReady = false;
  bool isDrawerOpen = false;
  dynamic errorMessage;

  @override
  void dispose() {
    pointAnnotationManager?.deleteAll();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchBusStops();
    _fetchRoutes();
  }

  Future<void> _fetchUserLocation(BuildContext context) async {
    if (!mounted) return;

    try {
      Position? position = await getCurrentLocation(context);
      _addUserMarker(
        mapbox.Point(
          coordinates: mapbox.Position(
            position?.longitude ?? 0.0,
            position?.latitude ?? 0.0,
          ),
        ),
      );
      if (position != null) {
        userLocation = position;
        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Unable to fetch user location';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
      return;
    }
  }

  Future<void> _fetchNearestStop(BuildContext context) async {
    if (userLocation == null) {
      await _fetchUserLocation(context);
    }

    NearestStop? nearestStop = await getNearestStop(
      userLocation!.latitude,
      userLocation!.longitude,
      routeId,
    );

    _drawNearestRoute(nearestStop);
  }

  void _drawNearestRoute(NearestStop nearestStop) async {
    if (!mounted) return;

    var coordinates = nearestStop.coordinates;
    await mapboxMap?.style.addSource(
      mapbox.GeoJsonSource(
        id: 'nearest_route',
        data: json.encode({
          "type": "Feature",
          "geometry": {"type": "LineString", "coordinates": coordinates},
        }),
      ),
    );

    await mapboxMap?.style.addLayer(
      mapbox.LineLayer(
        id: 'nearest_route_layer',
        sourceId: 'nearest_route',
        lineJoin: mapbox.LineJoin.ROUND,
        lineCap: mapbox.LineCap.ROUND,
        lineDasharray: [1, 1.5],
        lineColor: const Color.fromARGB(255, 108, 108, 155).toARGB32(),
        lineWidth: 3.0,
        slot: "bottom",
      ),
    );
  }

  Future<void> _fetchRoutes() async {
    if (!mounted) {
      return;
    }
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      List<String> busRoutes = await getAllRoutes();
      setState(() {
        routes = busRoutes;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _drawRouteAndStops() async {
    String url = stoppageUrlMaker(busStopLocations);
    if (!mounted) {
      return;
    }
    try {
      http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        var routeGeometry = data['routes'][0]['geometry'];

        var coordinates = routeGeometry['coordinates'].toList();

        await mapboxMap?.style.addSource(
          mapbox.GeoJsonSource(
            id: "route_$routeId",
            data: json.encode({
              "type": "Feature",
              "geometry": {"type": "LineString", "coordinates": coordinates},
            }),
          ),
        );

        await mapboxMap?.style.addLayer(
          mapbox.LineLayer(
            id: "route_layer_$routeId",
            sourceId: "route_$routeId",
            lineJoin: mapbox.LineJoin.ROUND,
            lineCap: mapbox.LineCap.ROUND,
            lineColor: const Color.fromARGB(255, 255, 150, 150).toARGB32(),
            lineWidth: 3.0,
            slot: "bottom",
          ),
        );

        mapboxMap?.annotations.createPointAnnotationManager().then((manager) {
          pointAnnotationManager = manager;
          pointAnnotationManager?.deleteAll();
          for (var busStop in busStopLocations) {
            _createMarker(busStop);
          }
        });

        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to fetch route data. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _fetchBusStops() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      List<BusStop> stops = await getAllBusStopsByRouteId(routeId);

      setState(() {
        busStopLocations = stops;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  void _onMapCreated(mapbox.MapboxMap mapBoxMap) {
    mapboxMap = mapBoxMap;
    _drawRouteAndStops();

    if (busStopLocations.isNotEmpty) {
      mapBoxMap.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: busStopLocations[0].position),
          zoom: 12.0,
        ),
        mapbox.MapAnimationOptions(duration: 2000),
      );
    }
  }

  void _addUserMarker(mapbox.Point uerLocation) {
    mapboxMap?.location.updateSettings(
      mapbox.LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingColor: const Color.fromARGB(255, 139, 155, 47).toARGB32(),
      ),
    );
  }

  void _createMarker(BusStop stop) {
    pointAnnotationManager
        ?.create(
          mapbox.PointAnnotationOptions(
            geometry: mapbox.Point(coordinates: stop.position),
            iconImage: "bus",
            textField: stop.name,
            textSize: 14.0,
            textColor: const Color.fromARGB(255, 0, 0, 0).toARGB32(),
            iconColor: const Color.fromARGB(255, 0, 0, 0).toARGB32(),
            iconSize: 2.0,
            iconOffset: [0.0, -10.0],
          ),
        )
        .then(
          (annotation) => {
            setState(() {
              pointAnnotations?.add(annotation);
            }),
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            children: [
              const Text(
                'Bus Route Map',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
              _fetchBusStops();
            },
          ),
          IconButton(
            icon: const Icon(Icons.alt_route),
            onPressed: () {
              _openModal(context);
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  void _openModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      pageBuilder: (contxt, animation1, animation2) {
        return Container();
      },
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation1, animation2, widget) {
        return ScaleTransition(
          scale: Tween(begin: 0.0, end: 1.0).animate(animation1),
          child: FadeTransition(
            opacity: Tween(begin: 0.0, end: 1.0).animate(animation1),
            child: AlertDialog(
              title: const Text('Select Route'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.2,
                child: ListView.builder(
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(routes[index]),
                      onTap: () {
                        setState(() {
                          routeId = routes[index];
                          isLoading = true;
                          errorMessage = null;
                        });
                        Navigator.of(context).pop();
                        _fetchBusStops();
                        _fetchRoutes();
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomDrawerContainer(BuildContext context) {
    double height = MediaQuery.of(context).size.height * 0.4;
    double width = MediaQuery.of(context).size.width;
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.0),
        topRight: Radius.circular(20.0),
      ),
      child: GestureDetector(
        onPanEnd: (details) {
          if (details.velocity.pixelsPerSecond.dy > 50) {
            setState(() {
              isDrawerOpen = false;
            });
          } else if (details.velocity.pixelsPerSecond.dy < -50) {
            setState(() {
              isDrawerOpen = true;
            });
          }
        },
        child: Container(
          color: const Color.fromARGB(255, 49, 49, 49),
          width: width,
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 10.0,
            ),
            child: Column(
              children: [
                AnimatedRotation(
                  curve: Curves.easeInOut,
                  turns: isDrawerOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Route - $routeId',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),
                Expanded(
                  child: ListView.builder(
                    itemCount: busStopLocations.length,
                    itemBuilder: (context, index) {
                      BusStop stop = busStopLocations[index];
                      return GestureDetector(
                        onTap: () {
                          mapboxMap?.flyTo(
                            mapbox.CameraOptions(
                              center: mapbox.Point(coordinates: stop.position),
                              zoom: 14.0,
                            ),
                            mapbox.MapAnimationOptions(duration: 1000),
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5.0),
                              padding: const EdgeInsets.symmetric(
                                vertical: 25.0,
                                horizontal: 15.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.directions_bus_outlined,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      stop.name,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (index < busStopLocations.length - 1)
                              const Divider(color: Colors.grey),
                            SizedBox(height: 10),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }

    return Stack(
      children: [
        mapbox.MapWidget(
          styleUri: mapbox.MapboxStyles.LIGHT,
          onMapCreated: _onMapCreated,
        ),
        AnimatedPositioned(
          curve: Curves.easeInOut,
          duration: const Duration(milliseconds: 300),
          left: 0,
          bottom: (isDrawerOpen)
              ? 0
              : -MediaQuery.of(context).size.height * 0.4 + 90,
          child: _buildBottomDrawerContainer(context),
        ),
        AnimatedPositioned(
          curve: Curves.easeInOut,
          duration: const Duration(milliseconds: 300),
          bottom: isDrawerOpen
              ? MediaQuery.of(context).size.height * 0.4 + 100
              : 210,
          right: 20,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
              backgroundColor: Colors.white,
            ),
            onPressed: () async {
              // ignore: use_build_context_synchronously
              await _fetchNearestStop(context);
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.directions, color: Colors.black, size: 30),
            ),
          ),
        ),
        AnimatedPositioned(
          curve: Curves.easeInOut,
          duration: const Duration(milliseconds: 300),
          bottom: isDrawerOpen
              ? MediaQuery.of(context).size.height * 0.4 + 20
              : 130,
          right: 20,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
              backgroundColor: Colors.white,
            ),
            onPressed: !myLocationClicked
                ? () async {
                    setState(() {
                      myLocationClicked = true;
                    });
                    await _fetchUserLocation(context);
                    if (userLocation != null) {
                      mapboxMap?.flyTo(
                        mapbox.CameraOptions(
                          center: mapbox.Point(
                            coordinates: mapbox.Position(
                              userLocation!.longitude,
                              userLocation!.latitude,
                            ),
                          ),
                          zoom: 14.0,
                        ),
                        mapbox.MapAnimationOptions(duration: 300),
                      );
                    }
                    setState(() {
                      myLocationClicked = false;
                    });
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.my_location, color: Colors.black, size: 30),
            ),
          ),
        ),
      ],
    );
  }
}