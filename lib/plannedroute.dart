import 'package:latlong2/latlong.dart';

class _RoutePoint {
  final LatLng point;
  final double distance;
  final double elevation;

  const _RoutePoint(this.point, this.distance, this.elevation);
}

class PlannedRoute {
  late final List<_RoutePoint> _routePoints;

  get path => _routePoints.map((e) => e.point).toList();

  double distanceToPoint(LatLng point) {
    double minDist = double.infinity;
    int minIndex = 0;
    for (int i = 0; i < _routePoints.length; i++) {
      final dist = _latLngDistance(_routePoints[i].point, point);
      if (dist < minDist) {
        minDist = dist;
        minIndex = i;
      }
    }
    return _routePoints[minIndex].distance;
  }

  double _latLngDistance(LatLng a, LatLng b) {
    // absolute value of number
    return (a.latitude - b.latitude).abs() * 111000 +
        (a.longitude - b.longitude).abs() * 47000;
  }

  PlannedRoute.fromGeoJson(dynamic geojson) : _routePoints = [] {
    // : _path = (geojson["geometry"]["coordinates"] as List<dynamic>).map((e) => LatLng(e[1], e[0])).toList()
    final coords = geojson["geometry"]["coordinates"]
        .map((e) => LatLng(e[1], e[0]))
        .toList();
    for (var i = 0; i < coords.length; i++) {
      _routePoints.add(_RoutePoint(
        coords[i],
        geojson["geometry"]["properties"]["measured"][i],
        geojson["geometry"]["coordinates"][i][2],
      ));
    }
  }
}
