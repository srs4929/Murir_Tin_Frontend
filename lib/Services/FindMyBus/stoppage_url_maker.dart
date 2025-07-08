import 'package:front/Models/bus_stop.dart';

String stoppageUrlMaker(List<BusStop> busStopLocations) {
  String accessToken = const String.fromEnvironment("ACCESS_TOKEN");
  String drivingPathBaseUrl =
      "https://api.mapbox.com/directions/v5/mapbox/driving/";

  drivingPathBaseUrl +=
      "${busStopLocations[0].longitude},${busStopLocations[0].latitude}";
  for (var busStop in busStopLocations.sublist(1)) {
    drivingPathBaseUrl += ";${busStop.longitude},${busStop.latitude}";
  }
  drivingPathBaseUrl +=
      "?alternatives=false&geometries=geojson&overview=full&steps=false&access_token=$accessToken";
  return drivingPathBaseUrl;
}
