import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geohash_plus_firestore/geohash_plus_firestore.dart';

void main() {
  final fireStore = FakeFirebaseFirestore();
  final col = fireStore.collection('user');
  late final DocumentReference<Map<String, dynamic>> store1ref, store2ref;

  setUpAll(() async {
    final store1 = GeohashStore(57.64911, 10.40744);
    store1ref = await col.add({
      'location': store1.data,
      'name': 'test1',
      'age': 30,
    });
    final store2 = GeohashStore(57.64922, 10.40755);
    store2ref = await col.add({
      'location': store2.data,
      'name': 'test2',
      'age': 40,
    });
    final store3 = GeohashStore(57.64899, 10.40755);
    await col.add({
      'location': store3.data,
      'name': 'test3',
      'age': 50,
    });
    final store4 = GeohashStore(57.66, 10.41);
    await col.add({
      'location': store4.data,
      'name': 'test4',
      'age': 60,
    });
  });

  test('create object', () async {
    final store = GeohashStore(57.64911, 10.40744);
    expect(store.geohash.hash, 'D12B7D7996B');
    expect(store.point, const GeoPoint(57.64911, 10.40744));
    expect(store.data['point'], const GeoPoint(57.64911, 10.40744));
    expect(store.data['geohash'], 'D12B7D7996B');
    expect(store.data['hierarchy'], [
      'D',
      'D1',
      'D12',
      'D12B',
      'D12B7',
      'D12B7D',
      'D12B7D7',
      'D12B7D79',
      'D12B7D799',
      'D12B7D7996',
      'D12B7D7996B'
    ]);
  });

  group('query', () {
    final bounds = LatLngBounds(
      northEast: LatLng(57.650, 10.408),
      southWest: LatLng(57.649, 10.407),
    );
    test('array', () async {
      final result = await GeohashQuery.withinBounds(bounds,
          query: col, field: 'location');
      expect(result.documents.length, 2);
      expect(result.documents.first.id, store1ref.id);
      expect(result.documents.last.id, store2ref.id);
      expect(result.searched, ['D12B7D79C', 'D12B7D799']);
    });
    test('order', () async {
      final result = await GeohashQuery.withinBounds(bounds,
          query: col, field: 'location', type: QueryType.order);
      expect(result.documents.length, 2);
      expect(result.documents.first.id, store1ref.id);
      expect(result.documents.last.id, store2ref.id);
      expect(result.searched, ['D12B7D79C', 'D12B7D799']);
    });
    test('exclude', () async {
      final result = await GeohashQuery.withinBounds(bounds,
          query: col, field: 'location', exclude: ['D12B7D799']);
      expect(result.documents.length, 0);
    });
    test('compound', () async {
      final query = col.where('age', isGreaterThan: 35);
      final result = await GeohashQuery.withinBounds(bounds,
          query: query, field: 'location');
      expect(result.documents.length, 1);
      expect(result.documents.first.id, store2ref.id);
    });
  });
}
