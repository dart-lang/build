// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import 'path_to_asset_id.dart';

/// A handler for `/$graph` requests under a specific `rootDir`.
class AssetGraphHandler {
  final AssetReader _reader;
  final String _rootPackage;
  final AssetGraph _assetGraph;

  AssetGraphHandler(this._reader, this._rootPackage, this._assetGraph);

  /// Returns a response with the  `$graph`, or with information about a
  /// specific node in the graph.
  ///
  /// For the path `$graph` returns the HTML page to render the graph.
  ///
  /// For any other path under `$graph/` will look for the assetNode referenced.
  /// Path patterns can be:
  /// - `$graph/packages/<package>/<path_under_lib>`
  /// - `$graph/<path_under_root_package>`
  /// - `$graph/<path_under_rootDir>`
  ///
  /// There may be some ambiguity between paths which are under the top-level of
  /// the root package, and those which are under the rootDir. Preference is
  /// given to the asset (if it exists) which is not under the implicit
  /// `rootDir`. For instance if the request is `$graph/web/main.dart` this will
  /// prefer to serve `<package>|web/main.dart`, but if it does not exist will
  /// fall back to `<package>|web/web/main.dart`.
  FutureOr<shelf.Response> handle(shelf.Request request, String rootDir) async {
    if (request.url.path == r'$graph') {
      return new shelf.Response.ok(
          await _reader.readAsString(
              new AssetId('build_runner', 'lib/src/server/graph_viz.html')),
          headers: {HttpHeaders.CONTENT_TYPE: 'text/html'});
    }
    if (request.url.path == r'$graph/assets.json') {
      var jsonContent = utf8.decode(_assetGraph.serialize());
      return new shelf.Response.ok(jsonContent,
          headers: {HttpHeaders.CONTENT_TYPE: 'application/json'});
    }
    var assetId = pathToAssetId(
        _rootPackage,
        request.url.pathSegments.skip(1).first,
        request.url.pathSegments.skip(2).toList());
    if (!_assetGraph.contains(assetId)) {
      assetId = pathToAssetId(
          _rootPackage, rootDir, request.url.pathSegments.skip(1).toList());
    }
    if (!_assetGraph.contains(assetId)) {
      return new shelf.Response.notFound('$assetId not present in build graph');
    }
    var node = _assetGraph.get(assetId);
    var currentEdge = 0;
    var nodes = [
      {'id': '${node.id}', 'label': '${node.id}'}
    ];
    var edges = <Map<String, String>>[];
    for (final output in node.outputs) {
      edges.add(
          {'from': '${node.id}', 'to': '$output', 'id': 'e${currentEdge++}'});
      nodes.add({'id': '$output', 'label': '$output'});
    }
    if (node is GeneratedAssetNode) {
      for (final input in node.inputs) {
        edges.add(
            {'from': '$input', 'to': '${node.id}', 'id': 'e${currentEdge++}'});
        nodes.add({'id': '$input', 'label': '$input'});
      }
    }
    var result = <String, dynamic>{
      'primary': {
        'id': '${node.id}',
        'isGenerated': node is GeneratedAssetNode,
        'globs': node is GeneratedAssetNode
            ? node.globs.map((g) => g.pattern).toList()
            : null,
        'hidden': node is GeneratedAssetNode ? node.isHidden : null,
        'state': node is GeneratedAssetNode ? '${node.state}' : null,
        'wasOutput': node is GeneratedAssetNode ? node.wasOutput : null,
        'isFailure': node is GeneratedAssetNode ? node.isFailure : null,
        'phaseNumber': node is GeneratedAssetNode ? node.phaseNumber : null,
      },
      'edges': edges,
      'nodes': nodes,
    };
    return new shelf.Response.ok(json.encode(result),
        headers: {HttpHeaders.CONTENT_TYPE: 'application/json'});
  }
}
