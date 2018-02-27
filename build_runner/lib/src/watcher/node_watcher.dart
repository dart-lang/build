// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build_runner/src/package_graph/package_graph.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import 'asset_change.dart';

typedef Watcher _WatcherStrategy(String path);
Watcher _default(String path) => new Watcher(path);

/// Allows watching significant files and directories in a given package.
class PackageNodeWatcher {
  final _WatcherStrategy _strategy;
  final PackageNode _node;

  /// The actual watcher instance.
  Watcher _watcher;
  Watcher get watcher => _watcher;

  /// Creates a new watcher for a [PackageNode].
  ///
  /// May optionally specify a [watch] strategy, otherwise will attempt a
  /// reasonable default based on the current platform and the type of path
  /// (i.e. a file versus directory).
  PackageNodeWatcher(
    this._node, {
    Watcher watch(String path),
  }) : _strategy = watch ?? _default;

  /// Returns a stream of records for assets that change recursively.
  ///
  /// If [relative] is omitted, the entire package is watched:
  /// ```dart
  /// // a/lib/**
  /// packageA.watch('lib');
  ///
  /// // a/**
  /// packageA.watch()
  /// ```
  Stream<AssetChange> watch([String relative]) {
    assert(_watcher == null);

    final path = _node.path;
    final absolute = relative != null ? p.join(path, relative) : path;
    _watcher = _strategy(absolute);
    final events = _watcher.events;
    return events.map((e) => new AssetChange.fromEvent(_node, e));
  }
}
