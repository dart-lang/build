// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:analyzer/analyzer.dart' show parseDirectives;
import 'package:build/build.dart';
import 'package:graphs/graphs.dart';

import 'package:analyzer/dart/ast/ast.dart';

typedef FutureOr<V> ReadNode<K, V>(K key);
typedef FutureOr<Iterable<K>> ReadEdges<K, V>(K key, V value);

/// Crawls Dart files outside of the SDK transitively imported from any library
/// in [entryPoints].
Future crawlImports(
    Iterable<AssetId> entryPoints, ReadNode<AssetId, String> readAsset) async {
  var roots = entryPoints.where((id) => id.path.endsWith('.dart'));
  await crawlAsync<AssetId, String>(roots, readAsset, _assetReferences).drain();
}

/// All the assets referenced by a [UriBasedDirective] in [source] that aren't
/// from the Dart SDK.
///
/// [id] represents the location of [source].
Iterable<AssetId> _assetReferences(AssetId id, String source) {
  if (source == null) return [];
  var unit = parseDirectives(source);
  return unit.directives
      .where((d) => d is UriBasedDirective)
      .map((d) => (d as UriBasedDirective).uri.stringValue)
      .where((uri) => !uri.startsWith('dart:'))
      .map((uri) => new AssetId.resolve(uri, from: id));
}
