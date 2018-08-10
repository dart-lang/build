// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library hot_reload_client;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

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

List<String> get moduleUrls {
  return List.from(jsArrayFrom(dartLoader.urlToModuleId.keys()));
}

String moduleIdByPath(String path) =>
    dartLoader.urlToModuleId.get(window.location.origin + '/' + path);

Future<Object> reloadModule(String moduleId) {
  var completer = Completer<Object>();
  dartLoader.forceLoadModule(moduleId, allowInterop(completer.complete));
  return completer.future;
}

class ReloadHandler {
  final String Function(String) _moduleIdByPath;
  final FutureOr<Object> Function(String) _reloadModule;
  final Map<String, String> _digests;

  ReloadHandler(this._digests,
      [this._moduleIdByPath = moduleIdByPath,
      this._reloadModule = reloadModule]);

  void listener(MessageEvent e) async {
    var updatedAssetDigests =
        json.decode(e.data as String) as Map<String, dynamic>;
    var moduleIdsToReload = <String>[];
    for (var path in updatedAssetDigests.keys) {
      if (_digests[path] == updatedAssetDigests[path]) {
        continue;
      }
      var moduleId = _moduleIdByPath(path);
      if (_digests.containsKey(path) && moduleId != null) {
        if (moduleId.endsWith('.ddc')) {
          moduleId = moduleId.substring(0, moduleId.length - 4);
        }
        moduleIdsToReload.add(moduleId);
      }
      _digests[path] = updatedAssetDigests[path] as String;
    }
    if (moduleIdsToReload.isNotEmpty) {
      await Future.wait(moduleIdsToReload
          .map((moduleId) => Future.value(_reloadModule(moduleId))));
      // TODO Search through dependency graph for true parents
      var mainModule = await _reloadModule('web/main');
      callMethod(getProperty(mainModule, 'main'), 'main', []);
    }
  }
}

main() async {
  var modulePaths = moduleUrls
      .map((key) => key.replaceFirst(window.location.origin + '/', ''))
      .toList();
  var modulePathsJson = json.encode(modulePaths);

  var request = await HttpRequest.request('/$_assetsDigestPath',
      responseType: 'json', sendData: modulePathsJson, method: 'POST');
  var digests = (request.response as Map).cast<String, String>();

  var handler = ReloadHandler(digests);

  var webSocket =
      WebSocket('ws://' + window.location.host, [_buildUpdatesProtocol]);
  webSocket.onMessage.listen(handler.listener);
}
