import 'package:murir_tin/Models/bus_stop.dart';

String stoppageUrlMaker(List<BusStop> busStopLocations) {
  String accessToken =
      "pk.eyJ1IjoidGFtaW03IiwiYSI6ImNtYzByY243djA2Y2UybHIydTllaHhudjIifQ.6zTjpL0hMo0oQWBt8KNHOQ";
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
