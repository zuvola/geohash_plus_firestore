# geohash_plus_firestore

[![pub package](https://img.shields.io/pub/v/geohash_plus_firestore.svg)](https://pub.dartlang.org/packages/geohash_plus_firestore)


**[English](https://github.com/zuvola/geohash_plus_firestore/blob/master/README.md), [日本語](https://github.com/zuvola/geohash_plus_firestore/blob/master/README_jp.md)**

カスタマイズ可能なGeohashの[geohash_plus](https://pub.dev/packages/geohash_plus)を用いてFirestoreでのジオクエリを実現します。  
デフォルトでは4bitのBase16エンコードに設定してあるので、通常のGeohashよりズームレベルによる精度の差が少なく、検索時のロスが少なくなります。  
また、クエリの方法は２種類用意してあるので、Firestoreの制限を回避するクエリを組み立てやすくなっています。  

[geohash_plus](https://pub.dev/packages/geohash_plus)は"１文字あたりのBit数"と "変換用アルファベット"をカスタマイズできるGeohashです。  
これにより通常のGeohashはBase32ですが、変換アルゴリズムはそのままでBase16など目的に合ったエンコード・デコードを行うことができます。  


## ドキュメントの追加

GeohashStoreオブジェクトを作成し、dataプロパティを指定して追加します。

```dart
final store = GeohashStore(57.64911, 10.40744);
db.collection('user').add({
  'location': store.data,
  'name': 'test1',
  'age': 30,
});
```


## データを取得する

エリアの座標を指定して矩形内にあるドキュメントを検索することができます。

```dart
final col = db.collection('user');
final bounds = LatLngBounds(
  northEast: LatLng(57.650, 10.408),
  southWest: LatLng(57.649, 10.407),
);
final result = await GeohashQuery.withinBounds(bounds,
    query: col, field: 'location');
```


## クエリ

queryにはCollectionReferenceまたはQueryを渡すことが可能です。  
クエリのタイプはarrayとorderがあり、それぞれ内部でarrayContainsAnyとorderByを使用しています。  
使用するクエリの種類によって使い分けてください。  
デフォルトはより通信回数の少ないarrayになっています。

```dart
final query = db.collection('user').where('age', isGreaterThan: 35);
final result = await GeohashQuery.withinBounds(bounds,
    query: query, field: 'location', type: QueryType.array);
```

