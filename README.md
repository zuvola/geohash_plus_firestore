# geohash_plus_firestore

[![pub package](https://img.shields.io/pub/v/geohash_plus_firestore.svg)](https://pub.dartlang.org/packages/geohash_plus_firestore)


**[English](https://github.com/zuvola/geohash_plus_firestore/blob/master/README.md), [日本語](https://github.com/zuvola/geohash_plus_firestore/blob/master/README_jp.md)**

Geo query in Firestore using [geohash_plus](https://pub.dev/packages/geohash_plus), a customizable Geohash.
The default encoding is set to 4-bit Base 16 encoding, so there is less difference in accuracy depending on zoom level than in normal Geohash, resulting in less loss during search.  
In addition, two query methods are available, making it easy to construct a query that avoids the limitations of Firestore.  

[geohash_plus](https://pub.dev/packages/geohash_plus) is a Geohash that allows you to customize the "number of bits per character" and "conversion alphabet".  
This allows you to encode and decode in Base16 or whatever suits your purposes without changing the conversion algorithm, whereas normal Geohash is in Base32.  


## Add a document

Create a GeohashStore object and add it by specifying the data property.

```dart
final store = GeohashStore(57.64911, 10.40744);
db.collection('user').add({
  'location': store.data,
  'name': 'test1',
  'age': 30,
});
```


## Searching for data

You can search for documents within a rectangle by specifying the coordinates of the area.

```dart
final col = db.collection('user');
final bounds = LatLngBounds(
  northEast: LatLng(57.650, 10.408),
  southWest: LatLng(57.649, 10.407),
);
final result = await GeohashQuery.withinBounds(bounds,
    query: col, field: 'location');
```


## Query

`query` can be passed as CollectionReference or Query.  
The query types are array and order, which use `arrayContainsAny` and `orderBy` internally, respectively.  
Use different types depending on the type of query you are using.
The default is array, which requires less communication.  

```dart
final query = db.collection('user').where('age', isGreaterThan: 35);
final result = await GeohashQuery.withinBounds(bounds,
    query: query, field: 'location', type: QueryType.array);
```

