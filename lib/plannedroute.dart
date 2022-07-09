import 'package:latlong2/latlong.dart';

class PlannedRoute {
  late final List<LatLng> _path;

  get path => _path;

  PlannedRoute(this._path);

  PlannedRoute.fromGeoJson(dynamic geojson) : _path = [] {
    // : _path = (geojson["geometry"]["coordinates"] as List<dynamic>).map((e) => LatLng(e[1], e[0])).toList()
    for (var c in geojson["geometry"]["coordinates"]) {
      _path.add(LatLng(c[1], c[0]));
    }
  }
}
