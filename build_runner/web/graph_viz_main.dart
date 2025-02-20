// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:js_interop';

import 'package:http/http.dart' as http;
import 'package:web/web.dart';

final _graphReference = window[r'$build'] as Graph;
final _details = document.getElementById('details')! as HTMLElement;

extension type Graph(JSObject _) implements JSObject {
  external void initializeGraph(JSFunction callback);

  external void setData(JSObject data);
}

void main() async {
  var filterBox = document.getElementById('filter') as HTMLInputElement;
  var searchBox = document.getElementById('searchbox') as HTMLInputElement;
  var searchForm = document.getElementById('searchform') as HTMLFormElement;
  searchForm.onSubmit.listen((e) {
    e.preventDefault();
    _focus(
      searchBox.value.trim(),
      filterBox.value.isNotEmpty ? filterBox.value : null,
    );
  });
  _graphReference.initializeGraph(_focus.toJS);
}

void _error(String message, [Object? error, StackTrace? stack]) {
  var msg = [message, error, stack].where((e) => e != null).join('\n');
  _details.innerHTML = '<pre>$msg</pre>'.toJS;
  console.error(msg.toJS);
}

void _focus(String query, [String? filter]) async {
  if (query.isEmpty) {
    _error('Provide content in the query.');
    return;
  }

  Map nodeInfo;
  var queryParams = {'q': query};
  if (filter != null) queryParams['f'] = filter;
  var uri = Uri(queryParameters: queryParams);

  var response = await http.get(uri);
  if (response.statusCode == 200) {
    nodeInfo = json.decode(response.body) as Map<String, dynamic>;
  } else {
    var msg = [
      'Error requesting query "$query".',
      '${response.statusCode} ${response.reasonPhrase ?? ''}',
      response.body,
    ].join('\n');
    _error(msg);
    return;
  }

  var graphData = {'edges': nodeInfo['edges'], 'nodes': nodeInfo['nodes']};
  _graphReference.setData(graphData.jsify() as JSObject);
  var primaryNode = nodeInfo['primary'] as Map<String, Object?>;
  _details.innerHTML =
      '<strong>ID:</strong> ${primaryNode['id']} <br />'
              '<strong>Type:</strong> ${primaryNode['type']}<br />'
              '<strong>Hidden:</strong> ${primaryNode['hidden']} <br />'
              '<strong>State:</strong> ${primaryNode['state']} <br />'
              '<strong>Was Output:</strong> ${primaryNode['wasOutput']} <br />'
              '<strong>Failed:</strong> ${primaryNode['isFailure']} <br />'
              '<strong>Phase:</strong> ${primaryNode['phaseNumber']} <br />'
              '<strong>Glob:</strong> ${primaryNode['glob']}<br />'
              '<strong>Last Digest:</strong> ${primaryNode['lastKnownDigest']}<br />'
          .toJS;
}
