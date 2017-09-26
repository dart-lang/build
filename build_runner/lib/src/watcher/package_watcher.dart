// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner/build_runner.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

/// An event that occurs when an [asset] change occurred due to [type].
class AssetChange {
  /// Asset that changed.
  final AssetId asset;

  /// Type of change that occurred.
  final ChangeType type;

  const AssetChange(this.asset, this.type);

  @override
  bool operator ==(o) => o is AssetChange && asset == o.asset && type == o.type;

  @override
  int get hashCode => asset.hashCode ^ type.hashCode;

  @override
  String toString() => 'AssetChange {$asset, $type}';
}

/// Abstraction for watching sub-directories in a given package for changes.
///
/// Changes emitted by [watch] are [AssetId]-based not (string) paths.
abstract class PackageWatcher {
  /// Create a package watcher for [graph], delegating to [watch] to create.
  factory PackageWatcher(PackageGraph graph, {Watcher watch(String path)}) =
      _PackageWatcher;

  /// Returns a stream of asset changes at a sub [path] in this package.
  Stream<AssetChange> watch(String path);
}

// Purposefully not a public API.
//
// TODO: Once the 2.0 SDK is stable, substitute for an inline function type.
typedef Watcher _CreateWatcher(String path);

// Actual (default) implementation that delegates to DirectoryWatcher.
class _PackageWatcher implements PackageWatcher {
  static Watcher _defaultWatch(String path) => new DirectoryWatcher(path);

  final _CreateWatcher _createWatcher;
  final PackageGraph _packageGraph;

  const _PackageWatcher(this._packageGraph,
      {_CreateWatcher watch: _defaultWatch})
      : _createWatcher = watch;

  @override
  Stream<AssetChange> watch(String path) {
    final url = _packageGraph.root.location;
    final from = url.toFilePath(windows: Platform.isWindows);
    final watch = p.absolute(from, path);
    final package = new AssetId(_packageGraph.root.name, from);
    return _createWatcher(watch).events.map((event) {
      return new AssetChange(
        new AssetId.resolve(event.path, from: package),
        event.type,
      );
    });
  }
}
