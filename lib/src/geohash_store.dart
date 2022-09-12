// (c) 2022 zuvola.

import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geohash_plus/geohash_plus.dart';

import 'options.dart';

/// Storing geographic information using Geohash
class GeohashStore {
  /// Geographical point
  final GeoPoint point;

  /// Geohash
  final GeoHash geohash;

  /// Data for export to Firestore
  late final Map<String, dynamic> data;

  /// Create an object from latitude and longitude
  GeohashStore(double latitude, double longitude,
      {GeohashOptions option = const GeohashOptions()})
      : geohash = GeoHash.encode(latitude, longitude,
            precision: option.precision,
            bits: option.bits,
            alphabet: option.alphabet),
        point = GeoPoint(latitude, longitude) {
    final hierarchy = <String>[];
    for (var i = 1; i < geohash.hash.length + 1; i++) {
      hierarchy.add(geohash.hash.substring(0, i));
    }
    data = UnmodifiableMapView({
      'point': point,
      'geohash': geohash.hash,
      'hierarchy': UnmodifiableListView(hierarchy),
    });
  }

  /// Import from Firestore
  factory GeohashStore.fromMap(Map<String, dynamic> map,
      {GeohashOptions option = const GeohashOptions()}) {
    final point = map['point'] as GeoPoint?;
    if (point == null) {
      throw ArgumentError();
    }
    return GeohashStore(point.latitude, point.longitude, option: option);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GeohashStore &&
        other.point == point &&
        other.geohash == geohash;
  }

  @override
  int get hashCode => point.hashCode ^ geohash.hashCode;

  @override
  String toString() =>
      'GeohashStore(latitude: ${point.latitude}, longitude: ${point.longitude}, geohash: ${geohash.hash})';
}
