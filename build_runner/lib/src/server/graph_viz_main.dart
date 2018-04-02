// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:html';
import 'dart:js';

final _graphReference = context[r'$build'];
final _details = document.getElementById('details');

main() async {
  var searchBox = document.getElementById('searchbox') as InputElement;
  var searchForm = document.getElementById('searchform');
  searchForm.onSubmit.listen((e) async {
    e.preventDefault();
    var query = searchBox.value;
    _focus(query);
    return null;
  });
  _graphReference.callMethod('initializeGraph', [_focus]);
}

void _focus(String query) async {
  var parts = query.split('|');
  var package = parts[0];
  var path = parts[1];
  var requestPath = path.startsWith('lib/')
      ? 'packages/$package/${path.substring(4)}'
      : '${path.split('/').skip(1).join('/')}';
  var nodeInfo =
      json.decode(await HttpRequest.getString('/\$graph/$requestPath'));
  var graphData = {'edges': nodeInfo['edges'], 'nodes': nodeInfo['nodes']};
  _graphReference.callMethod('setData', [new JsObject.jsify(graphData)]);
  var primaryNode = nodeInfo['primary'];
  _details.innerHtml = '<strong>ID:</strong> ${primaryNode['id']} <br />'
      '<strong>Generated:</strong> ${primaryNode['isGenerated']} <br />'
      '<strong>Hidden:</strong> ${primaryNode['hidden']} <br />'
      '<strong>State:</strong> ${primaryNode['state']} <br />'
      '<strong>Was Output:</strong> ${primaryNode['wasOutput']} <br />'
      '<strong>Failed:</strong> ${primaryNode['isFailure']} <br />'
      '<strong>Phase:</strong> ${primaryNode['phaseNumber']} <br />'
      '<strong>Globs:</strong> ${primaryNode['globs']} <br />';
}
