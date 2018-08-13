// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:graphs/graphs.dart' as graphs;

abstract class Module {
  bool get hasOnDestroy;

  bool get hasOnSelfUpdate;

  bool get hasOnChildUpdate;

  void onDestroy(Map data);

  bool onSelfUpdate(Map data);

  bool onChildUpdate(String childId, Module child, [Map data]);
}

/// Handles reloading order and hooks invocation
class ReloadingManager {
  final Future<Module> Function(String) _reloadModule;
  final Future<Module> Function(String) _loadModule;
  final void Function() _reloadPage;
  final List<String> Function(String moduleId) _moduleParents;
  final Iterable<String> Function() _allModules;

  final Map<String, int> _moduleOrdering = {};
  SplayTreeSet<String> _dirty;
  Completer<void> _running = Completer()..complete();

  int moduleTopologicalCompare(String module1, String module2) {
    var topological =
        Comparable.compare(_moduleOrdering[module2], _moduleOrdering[module1]);
    // If modules are in cycle (same strongly connected component) compare their
    // string id, to ensure total ordering for SplayTreeSet uniqueness.
    return topological != 0 ? topological : module1.compareTo(module2);
  }

  void updateGraph() {
    var allModules = _allModules();
    var stronglyConnectedComponents = graphs.stronglyConnectedComponents(
        allModules, (x) => x, _moduleParents);
    _moduleOrdering.clear();
    for (var i = 0; i < stronglyConnectedComponents.length; i++) {
      for (var module in stronglyConnectedComponents[i]) {
        _moduleOrdering[module] = i;
      }
    }
  }

  ReloadingManager(this._reloadModule, this._loadModule, this._reloadPage,
      this._moduleParents, this._allModules) {
    _dirty = SplayTreeSet(moduleTopologicalCompare);
  }

  Future<void> run(List<String> modules) async {
    _dirty.addAll(modules);

    // As function is async, it can potentially be called second time while
    // first invocation is still running. In this case just mark as dirty and
    // wait until loop from the first call will do the work
    if (!_running.isCompleted) return await _running.future;
    _running = Completer();

    while (_dirty.isNotEmpty) {
      var moduleId = _dirty.first;
      _dirty.remove(moduleId);

      var existing = await _loadModule(moduleId);
      Map data;
      if (existing.hasOnDestroy) {
        data = {};
        existing.onDestroy(data);
      }

      var newVersion = await _reloadModule(moduleId);
      bool success;
      if (newVersion.hasOnSelfUpdate) {
        success = newVersion.onSelfUpdate(data);
      }
      if (success == true) continue;
      if (success == false) {
        _reloadPage();
        _running.complete();
        return;
      }

      var parentIds = _moduleParents(moduleId);
      if (parentIds == null || parentIds.isEmpty) {
        _reloadPage();
        _running.complete();
        return;
      }
      parentIds.sort(moduleTopologicalCompare);
      for (var parentId in parentIds) {
        var parentModule = await _loadModule(parentId);
        if (parentModule.hasOnChildUpdate) {
          success = parentModule.onChildUpdate(moduleId, newVersion, data);
        }
        if (success == true) continue;
        if (success == false) {
          _reloadPage();
          _running.complete();
          return;
        }
        _dirty.add(parentId);
      }
    }
    _running.complete();
  }
}
