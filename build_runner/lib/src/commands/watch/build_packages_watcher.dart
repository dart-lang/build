// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import '../../build_plan/build_package.dart';
import '../../build_plan/build_packages.dart';
import '../../logging/build_log.dart';
import 'asset_change.dart';
import 'build_package_watcher.dart';

BuildPackageWatcher _default(BuildPackage buildPackage) =>
    BuildPackageWatcher(buildPackage);

/// Watches the watchable packages in a [BuildPackages] for file changes.
class BuildPackagesWatcher {
  final BuildPackageWatcher Function(BuildPackage) _strategy;
  final BuildPackages _buildPackages;

  final _readyCompleter = Completer<void>();
  Future<void> get ready => _readyCompleter.future;

  bool _isWatching = false;

  /// Creates a new watcher for a [BuildPackages].
  ///
  /// Optionally override watch strategy [watch] for testing.
  new(
    this._buildPackages, {
    BuildPackageWatcher Function(BuildPackage)? watch,
  }) : _strategy = watch ?? _default;

  /// Returns a stream of records for assets that changed in the build packages.
  Stream<AssetChange> watch() {
    assert(!_isWatching);
    _isWatching = true;
    return LazyStream(_watch);
  }

  Stream<AssetChange> _watch() {
    final forest = _buildPackageForest();
    final watchers = <BuildPackageWatcher>[];
    final events = <Stream<AssetChange>>[];

    for (final tree in forest) {
      final watcher = _strategy(tree.package);
      watchers.add(watcher);

      final stream = watcher.watch().map(tree.moveToDeepestPackage);
      events.add(
        stream.handleError((Object e, StackTrace s) {
          buildLog.error(
            buildLog.renderThrowable(
              'Failed to watch files in '
              'package:${watcher.buildPackage.name}.',
              e,
            ),
          );
        }),
      );
    }

    // Asynchronously complete the `_readyCompleter` once all the watchers
    // are done.
    () async {
      final readyFutures = <Future<void>>[];
      for (final watcher in watchers) {
        readyFutures.add(watcher.watcher.ready);
      }
      await Future.wait(readyFutures);
      _readyCompleter.complete();
    }();
    return StreamGroup.merge(events);
  }

  /// Builds a forest of [WatchablePackageTree] with all watchable packages.
  List<WatchablePackageTree> _buildPackageForest() {
    final watchablePackages = <BuildPackage>[];
    for (final p in _buildPackages.packages.values) {
      if (p.watch) watchablePackages.add(p);
    }
    watchablePackages.sort((a, b) => a.path.length.compareTo(b.path.length));
    final result = <WatchablePackageTree>[];
    for (final package in watchablePackages) {
      var inserted = false;
      for (final tree in result) {
        if (tree.insert(package)) {
          inserted = true;
          break;
        }
      }
      if (!inserted) {
        result.add(WatchablePackageTree(package));
      }
    }
    return result;
  }
}

/// A tree of watchable packages that share a common prefix.
class WatchablePackageTree {
  final BuildPackage package;
  final String packagePathWithSeparator;
  final List<WatchablePackageTree> children = [];

  new(this.package)
    : packagePathWithSeparator = package.path + Platform.pathSeparator;

  /// Recursively inserts [newPackage] as a child if it is nested under this
  /// package.
  ///
  /// Returns `true` if [newPackage] belongs in this subtree.
  bool insert(BuildPackage newPackage) {
    if (!newPackage.path.startsWith(packagePathWithSeparator)) {
      return false;
    }

    for (final child in children) {
      if (child.insert(newPackage)) {
        return true;
      }
    }

    children.add(WatchablePackageTree(newPackage));
    return true;
  }

  /// Finds the deepest nested package in this subtree that contains [path].
  ///
  /// Returns `null` if [path] does not belong to this package tree.
  BuildPackage? deepestPackageForPath(String path) {
    if (path != package.path && !path.startsWith(packagePathWithSeparator)) {
      return null;
    }

    for (final child in children) {
      final match = child.deepestPackageForPath(path);
      if (match != null) return match;
    }

    return package;
  }

  /// Moves [change] to the deepest matching package in the tree.
  ///
  /// Throws if it's not in the tree.
  AssetChange moveToDeepestPackage(AssetChange change) {
    final absolutePath = p.join(package.path, change.id.platformPath);
    final deepestPackage = deepestPackageForPath(absolutePath);
    if (deepestPackage == null) {
      throw StateError('No package found for path: $absolutePath');
    }
    if (deepestPackage == package) {
      return change;
    }
    final relativePath = p.relative(absolutePath, from: deepestPackage.path);
    return AssetChange(AssetId(deepestPackage.name, relativePath), change.type);
  }
}

extension _AssetIdExtension on AssetId {
  // Returns [path] with platform separators.
  String get platformPath =>
      Platform.isWindows ? path.replaceAll('/', r'\') : path;
}
