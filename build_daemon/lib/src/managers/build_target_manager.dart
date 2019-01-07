// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:watcher/watcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../data/build_target_request.dart';

bool _isBlacklistedPath(String filePath, Set<RegExp> blackListedPatterns) {
  // Ignore the first three directories when filtering as these often
  // relate to team directories which can contain black listed patterns.
  var splitPath = filePath.split('/');
  // TODO(grouma) - We'll want to refactor this so that the WatchEvent stream
  // provided by the google3 build daemon does this automatically.
  var path = splitPath.length > 3
      ? '/${splitPath.sublist(3).join('/')}'
      : splitPath.join('/');
  if (blackListedPatterns.any((pattern) => path.contains(pattern))) {
    return true;
  }
  return false;
}

class BuildTarget {
  // The build system identifier for the target.
  final String target;

  // Set of channels interested in this target.
  final listeners = Set<WebSocketChannel>();

  final Set<RegExp> _patterns;

  BuildTarget(
      this.target, Set<String> blackListPatterns, WebSocketChannel listener)
      : _patterns = blackListPatterns.map((p) => RegExp(p)).toSet() {
    listeners.add(listener);
  }

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) =>
      other is BuildTarget &&
      other.target == target &&
      other._patterns
          .map((p) => p.pattern)
          .toSet()
          .difference(_patterns.map((p) => p.pattern).toSet())
          .isEmpty;

  bool shouldBuild(List<WatchEvent> changes) =>
      changes.any((change) => !_isBlacklistedPath(change.path, _patterns));
}

/// Manages the set of build targets, and corersponding listeners, tracked by
/// the Dart Build Daemon.
class BuildTargetManager {
  final _buildTargets = Set<BuildTarget>();

  bool get isEmpty => _buildTargets.isEmpty;

  Set<BuildTarget> get targets => _buildTargets;

  void addBuildTarget(BuildTargetRequest request, WebSocketChannel channel) {
    var buildTarget =
        BuildTarget(request.target, request.blackListPattern.toSet(), channel);
    var existingTarget =
        _buildTargets.firstWhere((b) => b == buildTarget, orElse: () => null);
    if (existingTarget != null) {
      existingTarget.listeners.add(channel);
    } else {
      _buildTargets.add(buildTarget);
    }
  }

  void removeChannel(WebSocketChannel channel) {
    var toRemove = <BuildTarget>[];
    // Find the set of Build Targets that no longer have any listeners.
    for (var buildTarget in _buildTargets) {
      buildTarget.listeners.remove(channel);
      if (buildTarget.listeners.isEmpty) toRemove.add(buildTarget);
    }
    _buildTargets.removeAll(toRemove);
  }

  Set<BuildTarget> targetsForChanges(List<WatchEvent> changes) =>
      _buildTargets.where((target) => target.shouldBuild(changes)).toSet();
}
