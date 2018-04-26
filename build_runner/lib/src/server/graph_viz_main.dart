// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js' as js;

final _graphReference = js.context[r'$build'];
final _details = document.getElementById('details');

main() async {
  var searchBox = document.getElementById('searchbox') as InputElement;
  var searchForm = document.getElementById('searchform');
  searchForm.onSubmit.listen((e) {
    e.preventDefault();
    _focus(searchBox.value);
    return null;
  });
  _graphReference.callMethod('initializeGraph', [_focus]);
}

void _error(String message, [Object error, StackTrace stack]) {
  var msg = [message, error, stack].where((e) => e != null).join('\n');
  _details.innerHtml = '<pre>$msg</pre>';
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
    _error('The query you provided "$query" could not be parsed.', e, stack);
    return;
  }

  var url = '/\$graph/$requestPath';
  Map nodeInfo;
  try {
    nodeInfo =
        json.decode(await HttpRequest.getString(url)) as Map<String, dynamic>;
  } catch (e, stack) {
    var msg = 'Error making a request: $url';
    if (e is ProgressEvent) {
      var target = e.target;
      if (target is HttpRequest) {
        msg = [
          msg,
          '${target.status} ${target.statusText}',
          target.responseText
        ].join('\n');
      }
      _error(msg);
    } else {
      _error(msg, e, stack);
    }
    return;
  }

  var graphData = {'edges': nodeInfo['edges'], 'nodes': nodeInfo['nodes']};
  _graphReference.callMethod('setData', [new js.JsObject.jsify(graphData)]);
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
