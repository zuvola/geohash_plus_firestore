// (c) 2022 zuvola.

import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geohash_plus/geohash_plus.dart';
import 'package:geohash_plus_firestore/src/options.dart';

enum QueryType {
  array,
  order,
}

/// Search results for GeohashQuery
class GeohashQueryResult<T> {
  /// Represents query results returned from Firestore.
  final List<QueryDocumentSnapshot<T>> documents;

  /// Geohash codes used for the query
  final List<String> searched;

  GeohashQueryResult(this.documents, this.searched);
}

/// Geographic search class using Geohash.
class GeohashQuery {
  GeohashQuery._();

  /// Search within the area of [bounds].
  static Future<GeohashQueryResult<T>> withinBounds<T>(
    LatLngBounds bounds, {
    required Query<T> query,
    required String field,
    List<String> exclude = const [],
    QueryType type = QueryType.array,
    bool clip = true,
    GetOptions? options,
    GeohashCoverOptions coverOptions = const GeohashCoverOptions(),
  }) async {
    final cover = GeoHash.coverBounds(
      bounds,
      maxPrecision: coverOptions.maxPrecision,
      threshold: coverOptions.threshold,
      bits: coverOptions.bits,
      alphabet: coverOptions.alphabet,
    ).entries.lastWhere((item) => item.value.length < 10);
    final hashes = cover.value.map((e) => e.hash).toList();
    hashes.removeWhere((item) => exclude.contains(item));

    List<QueryDocumentSnapshot<T>> docs;
    if (type == QueryType.array) {
      final snapshot = await query
          .where('$field.hierarchy', arrayContainsAny: hashes)
          .get(options);
      docs = snapshot.docs;
    } else {
      final queries = hashes.map((hash) {
        return query
            .orderBy('$field.geohash')
            .startAt([hash]).endAt(['$hash\uffff']).get(options);
      }).toList();
      final snapshots = await Future.wait(queries);
      docs = snapshots.expand((e) => e.docs).toList();
    }
    if (clip) {
      docs = docs.where((doc) {
        final point = doc.get('$field.point') as GeoPoint;
        return bounds.contains(LatLng(point.latitude, point.longitude));
      }).toList();
    }
    return GeohashQueryResult(
      UnmodifiableListView(docs),
      UnmodifiableListView(hashes),
    );
  }
}
