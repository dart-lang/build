// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
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
    await _focus(query);
    return null;
  });
  _graphReference.callMethod('initializeGraph', [_focus]);
}

void _error(String message, Object error, StackTrace stack) {
  // TODO: update the user page some how?
  window.console.error(message);
  window.console.log(error);
  window.console.log(stack);
}

Future _focus(String query) async {
  String requestPath;
  try {
    var parts = query.split('|');
    var package = parts[0];
    var path = parts[1];
    requestPath = path.startsWith('lib/')
        ? 'packages/$package/${path.substring(4)}'
        : '${path.split('/').skip(1).join('/')}';
  } catch (e, stack) {
    _error('The query you provided ($query) could not be parsed.', e, stack);
    return;
  }

  Map nodeInfo;
  try {
    nodeInfo = json.decode(await HttpRequest.getString('/\$graph/$requestPath'))
        as Map<String, dynamic>;
  } catch (e, stack) {
    _error('Got an error making a request.', e, stack);
    return;
  }

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
