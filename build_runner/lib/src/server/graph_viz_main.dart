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
      .map((node) => {'id': node.id.toString(), 'label': node.id.toString()})
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
