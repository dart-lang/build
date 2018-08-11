// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library hot_reload_client;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:build_runner/src/server/hot_reload_client/reload_handler.dart';

import 'package:js/js.dart';
import 'package:js/js_util.dart';

final _assetsDigestPath = r'$assetDigests';
final _buildUpdatesProtocol = r'$livereload';

@JS('Map')
abstract class JsMap<K, V> {
  @JS()
  external Object keys();

  @JS()
  external V get(K key);
}

@anonymous
@JS()
class DartLoader {
  @JS()
  external JsMap<String, String> get urlToModuleId;

  @JS()
  external void forceLoadModule(
      String moduleId, void Function(Object module) callback);
}

@JS(r'$dartLoader')
external DartLoader get dartLoader;

@JS('Array.from')
external List jsArrayFrom(Object any);

List<String> get _moduleUrls {
  return List.from(jsArrayFrom(dartLoader.urlToModuleId.keys()));
}

String _moduleIdByPath(String path) =>
    dartLoader.urlToModuleId.get(window.location.origin + '/' + path);

Future<Object> _reloadModule(String moduleId) {
  var completer = Completer<Object>();
  dartLoader.forceLoadModule(moduleId, allowInterop(completer.complete));
  return completer.future;
}

main() async {
  var modulePaths = _moduleUrls
      .map((key) => key.replaceFirst(window.location.origin + '/', ''))
      .toList();
  var modulePathsJson = json.encode(modulePaths);

  var request = await HttpRequest.request('/$_assetsDigestPath',
      responseType: 'json', sendData: modulePathsJson, method: 'POST');
  var digests = (request.response as Map).cast<String, String>();

  var handler = ReloadHandler(digests, _moduleIdByPath, _reloadModule,
      (module) => callMethod(getProperty(module, 'main'), 'main', []));

  var webSocket =
      WebSocket('ws://' + window.location.host, [_buildUpdatesProtocol]);
  webSocket.onMessage.listen((event) => handler.listener(event.data as String));
}
