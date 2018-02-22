// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:html';
import 'dart:js';

import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';

main() async {
  var json = await HttpRequest.getString(r'/$graph/assets.json');
  var graph = new AssetGraph.deserialize(UTF8.encode(json));
  var nodes = graph.allNodes
      .where((node) {
        if (node is GeneratedAssetNode && !node.wasOutput) return false;
        return true;
      })
      .map((node) => {
            'id': node.id.toString(),
            'label': node.id.toString(),
            'info': {
              'isGenerated': node is GeneratedAssetNode,
              'globs': node is GeneratedAssetNode
                  ? node.globs.map((g) => g.pattern)
                  : null,
              'hidden': node is GeneratedAssetNode ? node.isHidden : null,
              'state':
                  node is GeneratedAssetNode ? node.state.toString() : null,
              'wasOutput': node is GeneratedAssetNode ? node.wasOutput : null,
              'phaseNumber':
                  node is GeneratedAssetNode ? node.phaseNumber : null,
            }
          })
      .toList();
  int edgeNum = 0;
  var edges = graph.allNodes.expand((node) {
    if (node is GeneratedAssetNode && !node.wasOutput) return [];
    return node.outputs.map((out) {
      return {
        'from': node.id.toString(),
        'to': out.toString(),
        'id': 'e${edgeNum++}',
      };
    });
  }).toList();
  var data = {
    'nodes': nodes,
    'edges': edges,
  };
  context[r'$build'].callMethod('initializeGraph', [new JsObject.jsify(data)]);
}
