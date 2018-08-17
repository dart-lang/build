// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'reloading_manager.dart';

/// Provides [listener] to handle web socket connection and reload invalidated
/// modules using [ReloadingManager]
class ReloadHandler {
  final String Function(String) _moduleIdByPath;
  final Map<String, String> _digests;
  final ReloadingManager _reloadingManager;

  ReloadHandler(this._digests, this._moduleIdByPath, this._reloadingManager);

  void listener(String data) async {
    var updatedAssetDigests = json.decode(data) as Map<String, dynamic>;
    var moduleIdsToReload = <String>[];
    for (var path in updatedAssetDigests.keys) {
      if (_digests[path] == updatedAssetDigests[path]) {
        continue;
      }
      var moduleId = _moduleIdByPath(path);
      if (_digests.containsKey(path) && moduleId != null) {
        moduleIdsToReload.add(moduleId);
      }
      _digests[path] = updatedAssetDigests[path] as String;
    }
    if (moduleIdsToReload.isNotEmpty) {
      _reloadingManager.updateGraph();
      await _reloadingManager.reload(moduleIdsToReload);
    }
  }
}
