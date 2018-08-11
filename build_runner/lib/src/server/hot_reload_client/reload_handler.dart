// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

/// Provides [listener] to handle web socket connection and reload invalidated
/// modules
class ReloadHandler {
  final String Function(String) _moduleIdByPath;
  final Future<Object> Function(String) _reloadModule;
  final void Function(Object) _callMainOnModule;
  final Map<String, String> _digests;

  ReloadHandler(this._digests, this._moduleIdByPath, this._reloadModule,
      this._callMainOnModule);

  void listener(String data) async {
    var updatedAssetDigests = json.decode(data) as Map<String, dynamic>;
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
      await Future.wait(moduleIdsToReload.map(_reloadModule));
      // TODO Search through dependency graph for true parents
      var mainModule = await _reloadModule('web/main');
      _callMainOnModule(mainModule);
    }
  }
}
