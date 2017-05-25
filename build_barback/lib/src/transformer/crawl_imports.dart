// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:analyzer/analyzer.dart' show parseDirectives;
import 'package:analyzer/src/generated/engine.dart' show TimestampedData;
import 'package:analyzer/src/generated/source.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import 'package:analyzer/dart/ast/ast.dart';

/// Crawl Dart files outside of the SDK transitively imported from any library
/// in [entryPoints] and cache it as a [Source].
Future<Map<Uri, Source>> crawlImports(
    Iterable<AssetId> entryPoints, Future<String> read(AssetId id)) async {
  var roots = entryPoints.where((id) => id.path.endsWith('.dart'));
  var assets = await _crawlAsync(roots, read, _assetImports);
  var results = <Uri, Source>{};
  for (var asset in assets.keys) {
    results[asset.uri] = _toSource(asset, assets[asset]);
  }
  return results;
}

Iterable<AssetId> _assetImports(AssetId id, String source) {
  var unit = parseDirectives(source);
  return unit.directives
      .where((d) => d is UriBasedDirective)
      .map((d) => d as UriBasedDirective)
      .map((d) => d.uri.stringValue)
      .where((uri) => !uri.startsWith('dart:'))
      .map((uri) => new AssetId.resolve(uri, from: id));
}

Source _toSource(AssetId id, String content) => new AssetSource(id, content);

/// Crawl a graph where node values and edges are resolved asynchronously.
///
/// Nodes are keyed by type [K] and have values of type [V]. [resolve] finds the
/// value for a node. [edges] finds the edges leaving a node.
Future<Map<K, V>> _crawlAsync<K, V>(
    Iterable<K> roots,
    FutureOr<V> resolve(K key),
    FutureOr<Iterable<K>> edges(K key, V value)) async {
  var seen = <K, Future<V>>{};
  await Future.wait(roots.map((k) => _visitNode(k, seen, resolve, edges)));
  var results = <K, V>{};
  for (var k in seen.keys) {
    results[k] = await seen[k];
  }
  return results;
}

/// Synchronously record the the node a [key] has been seen, then start the
/// work.
///
/// The returned Future will complete when the node at [key], and transitively
/// reachable nodes, have either finished their crawl or are guaranteed to be
/// completed within another future in [seen].
Future _visitNode<K, V>(K key, Map<K, Future<V>> seen,
    FutureOr<V> resolve(K key), FutureOr<Iterable<K>> edges(K key, V value)) {
  if (seen.containsKey(key)) return new Future.value(null);
  return seen[key] = _crawlFromNode(key, seen, resolve, edges);
}

/// Resolve the node at [key] and visit all transitively reachable nodes.
Future<V> _crawlFromNode<K, V>(
    K key,
    Map<K, Future<V>> seen,
    FutureOr<V> resolve(K key),
    FutureOr<Iterable<K>> edges(K key, V value)) async {
  var value = await resolve(key);
  var next = await edges(key, value) ?? [];
  await Future.wait(next.map((k) => _visitNode(k, seen, resolve, edges)));
  return value;
}

class AssetSource implements Source {
  final AssetId _assetId;
  final String _content;

  AssetSource(this._assetId, this._content);

  @override
  TimestampedData<String> get contents => new TimestampedData(0, _content);

  @override
  String get encoding => '$_assetId';

  @override
  String get fullName => '$_assetId';

  @override
  int get hashCode => _assetId.hashCode;

  @override
  bool get isInSystemLibrary => false;

  @override
  Source get librarySource => null;

  @override
  int get modificationStamp => 0;

  @override
  String get shortName => p.basename(_assetId.path);

  @override
  Source get source => this;

  @override
  Uri get uri => _assetId.uri;

  @override
  UriKind get uriKind {
    if (_assetId.path.startsWith('lib/')) return UriKind.PACKAGE_URI;
    return UriKind.FILE_URI;
  }

  @override
  bool operator ==(Object object) =>
      object is AssetSource && object._assetId == _assetId;

  @override
  bool exists() => true;

  @override
  String toString() => 'AssetSource[$_assetId]';
}
