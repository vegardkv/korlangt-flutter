import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:leaflet_test_1/plannedroute.dart';
import 'package:leaflet_test_1/config.dart';
import 'package:positioned_tap_detector_2/positioned_tap_detector_2.dart';
import 'package:http/http.dart' as http;
import 'package:geojson/geojson.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Name generator',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 0, 118, 2),
          foregroundColor: Color.fromARGB(255, 255, 255, 255),
        ),
      ),
      home: const RoutePlanner(),
    );
  }
}

class RoutePlanner extends StatefulWidget {
  const RoutePlanner({Key? key}) : super(key: key);

  @override
  State<RoutePlanner> createState() => _RoutePlannerState();
}

class _RoutePlannerState extends State<RoutePlanner> {
  final _markers = <LatLng>[];
  var _lastRequest = 0;
  PlannedRoute? _route;

  List<Marker> _buildMarkers() {
    return _markers.fold([], (prev, latlng) {
      final i = prev.length;
      prev.add(Marker(
        width: 18.0,
        height: 18.0,
        point: latlng,
        builder: (ctx) => InkWell(
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 0, 200, 0),
              border: Border.all(
                color: const Color.fromARGB(255, 255, 255, 255),
                width: 3.0,
              ),
              shape: BoxShape.circle,
            ),
          ),
          onTap: () => {
            setState(() {
              _markers.removeAt(i);
              _updatePath();
            })
          },
        ),
      ));
      return prev;
    });
  }

  void _updatePath() async {
    var now = DateTime.now().microsecondsSinceEpoch;
    setState(() {
      _route = null;
      _lastRequest = now;
    });
    if (_markers.length < 2) return;
    final features = await _fetchPath(now);
    if (features.statusCode != 200) {
      log("Failed to connect with error code ${features.statusCode}");
    } else {
      final int t = jsonDecode((features.request as http.Request).body)["t"];
      if (t != _lastRequest) {
        return;
      }
      final gj = jsonDecode(features.body);
      setState(() {
        _route = PlannedRoute.fromGeoJson(gj);
      });
    }
  }

  Future<http.Response> _fetchPath(int t) {
    const uri = Config.lambdaUri;
    final data = {
      "lat": _markers.map((e) => e.latitude).toList(),
      "lon": _markers.map((e) => e.longitude).toList(),
      "t": t,
    };
    return http.post(
      Uri.parse(uri),
      body: jsonEncode(data),
      headers: {
        "Content-Type": "application/json",
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = _buildMarkers();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Route Planner"),
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(60, 10),
          zoom: 11.0,
          onTap: _handleTap,
        ),
        nonRotatedChildren: [
          AttributionWidget.defaultWidget(
            source: "Open Street Map contributors",
            onSourceTapped: () {},
          ),
        ],
        children: [
          TileLayerWidget(
            options: TileLayerOptions(
              urlTemplate:
                  "https://opencache.statkart.no/gatekeeper/gk/gk.open_gmaps?layers=topo4&zoom={z}&x={x}&y={y}",
            ),
          ),
          PolylineLayerWidget(
            options: PolylineLayerOptions(
              polylines: [
                Polyline(
                  points: _route?.path ?? [],
                  strokeWidth: 2,
                  color: Color.fromARGB(255, 0, 100, 230),
                ),
              ],
            ),
          ),
          MarkerLayerWidget(
            options: MarkerLayerOptions(
              markers: markers,
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(TapPosition pos, LatLng latlng) {
    setState(() {
      _markers.add(latlng);
      _updatePath();
    });
  }
}
