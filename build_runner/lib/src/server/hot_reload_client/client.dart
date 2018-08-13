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

import 'reload_handler.dart';
import 'reloading_manager.dart';

final _assetsDigestPath = r'$assetDigests';
final _buildUpdatesProtocol = r'$livereload';

@anonymous
@JS()
abstract class HotReloadableModule {
  /// Implement this function with any code to release resources before destroy.
  ///
  /// If you need to save state of module, you can use [data] for this.
  ///
  /// This function will be called on old version of module before unloading.
  @JS()
  external void hot$onDestroy(Map data);

  /// Implement this function to handle update of the module itself.
  ///
  /// May return nullable bool. To indicate that reload completes successfully
  /// return true. To indicate that hot-reload is undoable return false - this
  /// will lead to full page reload. If null returned, reloading will be
  /// propagated to parent.
  ///
  /// If any state was saved from previous state, it will be passed to [data].
  /// Otherwise null will be passed.
  ///
  /// This function will be called on new version of module after reloading.
  @JS()
  external bool hot$onSelfUpdate(Map data);

  /// Implement this function to handle update of child modules.
  ///
  /// May return nullable bool. To indicate that reload of child completes
  /// successfully return true. To indicate that hot-reload is undoable for this
  /// child return false - this will lead to full page reload. If null returned,
  /// reloading will be propagated to current module itself.
  ///
  /// The name of the child will be provided in [childId]. New version of child
  /// module object will be provided in [child].
  /// If any state was saved from previous state, it will be passed to [data].
  /// Otherwise null will be passed.
  ///
  /// This function will be called on old version of module current after child
  /// reloading.
  @JS()
  external bool hot$onChildUpdate(String childId, HotReloadableModule child,
      [Map data]);
}

class ModuleWrapper implements Module {
  final HotReloadableModule _internal;

  ModuleWrapper(this._internal);

  @override
  bool get hasOnDestroy =>
      _internal != null && hasProperty(_internal, r'hot$onDestroy');

  @override
  bool get hasOnSelfUpdate =>
      _internal != null && hasProperty(_internal, r'hot$onSelfUpdate');

  @override
  bool get hasOnChildUpdate =>
      _internal != null && hasProperty(_internal, r'hot$onChildUpdate');

  @override
  void onDestroy(Map data) => _internal.hot$onDestroy(data);

  @override
  bool onSelfUpdate(Map data) => _internal.hot$onSelfUpdate(data);

  @override
  bool onChildUpdate(String childId, Module child, [Map data]) =>
      _internal
          .hot$onChildUpdate(childId, (child as ModuleWrapper)._internal, data);
}

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
  external JsMap<String, List<String>> get moduleParentsGraph;

  @JS()
  external void forceLoadModule(String moduleId,
      void Function(HotReloadableModule module) callback);

  @JS()
  external void loadModule(String moduleId,
      void Function(HotReloadableModule module) callback);
}

@JS(r'$dartLoader')
external DartLoader get dartLoader;

@JS('Array.from')
external List _jsArrayFrom(Object any);

List<K> keys<K, V>(JsMap<K, V> map) {
  return List.from(_jsArrayFrom(map.keys()));
}

Future<Module> _reloadModule(String moduleId) {
  var completer = Completer<Module>();
  dartLoader.forceLoadModule(
      moduleId,
      allowInterop((HotReloadableModule module) =>
          completer.complete(ModuleWrapper(module))));
  return completer.future;
}

Future<Module> _loadModule(String moduleId) {
  var completer = Completer<Module>();
  dartLoader.loadModule(
      moduleId,
      allowInterop((HotReloadableModule module) =>
          completer.complete(ModuleWrapper(module))));
  return completer.future;
}

void _reloadPage() {
  window.location.reload();
}

main() async {
  var currentOrigin = window.location.origin + '/';
  var modulePaths = keys(dartLoader.urlToModuleId)
      .map((key) => key.replaceFirst(currentOrigin, ''))
      .toList();
  var modulePathsJson = json.encode(modulePaths);

  var request = await HttpRequest.request('/$_assetsDigestPath',
      responseType: 'json', sendData: modulePathsJson, method: 'POST');
  var digests = (request.response as Map).cast<String, String>();

  var manager = ReloadingManager(
      _reloadModule,
      _loadModule,
      _reloadPage,
          (module) => dartLoader.moduleParentsGraph.get(module),
          () => keys(dartLoader.moduleParentsGraph));

  var handler = ReloadHandler(digests,
          (path) => dartLoader.urlToModuleId.get(currentOrigin + path),
      manager);

  var webSocket =
      WebSocket('ws://' + window.location.host, [_buildUpdatesProtocol]);
  webSocket.onMessage.listen((event) => handler.listener(event.data as String));
}
