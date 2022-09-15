import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:example/firebase_options.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide LatLngBounds;
import 'package:latlong2/latlong.dart' as latlong2;

import 'package:geohash_plus_firestore/geohash_plus_firestore.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _controller = MapController();
  final _fireStore = FakeFirebaseFirestore();
  // late final FirebaseFirestore _fireStore;
  final _searched = <String>[];
  final _circles = <String, CircleMarker>{};
  final _polygons = <String, Polygon>{};

  @override
  void initState() {
    setup();
    super.initState();
  }

  void setup() async {
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    // _fireStore = FirebaseFirestore.instance;
    final col = _fireStore.collection('users');
    final user = await col.limit(1).get();
    if (user.size == 0) {
      Future.wait(
        Iterable.generate(50).map((i) {
          final store = GeohashStore(
            51.4 + Random().nextDouble() / 5,
            -0.3 + Random().nextDouble() / 2,
          );
          return col.add({
            'location': store.data,
            'name': 'user_$i',
          });
        }),
      );
    }

    _controller.mapEventStream.listen((event) async {
      if (event.zoom < 10) return;
      if (event is MapEventMoveEnd) {
        final ne = _controller.bounds?.northEast;
        final sw = _controller.bounds?.southWest;
        if (ne == null || sw == null) return;
        final bounds = LatLngBounds(
          northEast: LatLng(ne.latitude, ne.longitude),
          southWest: LatLng(sw.latitude, sw.longitude),
        );
        final result = await GeohashQuery.withinBounds(bounds,
            query: col, field: 'location', clip: false, exclude: _searched);
        _searched.addAll(result.searched);
        for (var doc in result.documents) {
          final pos = doc.get('location.point') as GeoPoint;
          setState(() {
            _circles[doc.id] = CircleMarker(
              point: latlong2.LatLng(pos.latitude, pos.longitude),
              radius: 10,
              color: Colors.red,
            );
          });
        }
        for (var geohash in result.searched) {
          final bounds = GeoHash.decode(geohash, bits: 4).bounds;
          setState(() {
            _polygons[geohash] = Polygon(
              points: [
                latlong2.LatLng(
                    bounds.northEast.latitude, bounds.northEast.longitude),
                latlong2.LatLng(
                    bounds.northWest.latitude, bounds.northWest.longitude),
                latlong2.LatLng(
                    bounds.southWest.latitude, bounds.southWest.longitude),
                latlong2.LatLng(
                    bounds.southEast.latitude, bounds.southEast.longitude),
              ],
              borderColor: Colors.black45,
              borderStrokeWidth: 3,
              color: Colors.green.withOpacity(0.2),
              isFilled: true,
            );
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FlutterMap(
          mapController: _controller,
          options: MapOptions(
            center: latlong2.LatLng(51.509364, -0.128928),
            zoom: 14,
          ),
          nonRotatedChildren: [
            AttributionWidget.defaultWidget(
              source: 'OpenStreetMap contributors',
              onSourceTapped: null,
            ),
          ],
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            CircleLayer(
              circles: _circles.values.toList(),
            ),
            PolygonLayer(
              polygons: _polygons.values.toList(),
            ),
          ],
        ),
      ),
    );
  }
}
