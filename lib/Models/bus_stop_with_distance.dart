import 'package:murir_tin/Models/bus_stop.dart';

class BusStopWithDistance {
  final BusStop busStop;
  final double distanceInMeters;
  final double walkingTimeInSeconds;

  BusStopWithDistance({
    required this.busStop,
    required this.distanceInMeters,
    required this.walkingTimeInSeconds,
  });
}
