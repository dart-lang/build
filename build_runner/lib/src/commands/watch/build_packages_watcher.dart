// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';

import '../../build_plan/build_package.dart';
import '../../build_plan/build_packages.dart';
import '../../logging/build_log.dart';
import 'asset_change.dart';
import 'build_package_watcher.dart';

BuildPackageWatcher _default(BuildPackage buildPackage) =>
    BuildPackageWatcher(buildPackage);

/// Allows watching an entire graph of packages to schedule rebuilds.
class BuildPackagesWatcher {
  final BuildPackageWatcher Function(BuildPackage) _strategy;
  final BuildPackages _buildPackages;

  final _readyCompleter = Completer<void>();
  Future<void> get ready => _readyCompleter.future;

  bool _isWatching = false;

  /// Creates a new watcher for a [BuildPackages].
  ///
  /// May optionally specify a [watch] strategy, otherwise will attempt a
  /// reasonable default based on the current platform.
  BuildPackagesWatcher(
    this._buildPackages, {
    BuildPackageWatcher Function(BuildPackage)? watch,
  }) : _strategy = watch ?? _default;

  /// Returns a stream of records for assets that changed in the package graph.
  Stream<AssetChange> watch() {
    assert(!_isWatching);
    _isWatching = true;
    return LazyStream(_watch);
  }

  Stream<AssetChange> _watch() {
    final allWatchers =
        _buildPackages.allPackages.values
            .where((buildPackage) => buildPackage.isEditable)
            .map(_strategy)
            .toList();
    final filteredEvents =
        allWatchers
            .map(
              (w) => w
                  .watch()
                  .where(_nestedPathFilter(w.buildPackage))
                  .handleError((Object e, StackTrace s) {
                    buildLog.error(
                      buildLog.renderThrowable(
                        'Failed to watch files in '
                        'package:${w.buildPackage.name}.',
                        e,
                      ),
                    );
                  }),
            )
            .toList();
    // Asynchronously complete the `_readyCompleter` once all the watchers
    // are done.
    () async {
      await Future.wait(
        allWatchers.map((packageWatcher) => packageWatcher.watcher.ready),
      );
      _readyCompleter.complete();
    }();
    return StreamGroup.merge(filteredEvents);
  }

  bool Function(AssetChange) _nestedPathFilter(BuildPackage rootPackage) {
    final ignorePaths = _nestedPaths(rootPackage);
    return (change) => !ignorePaths.any(change.id.path.startsWith);
  }

  // Returns a set of all package paths that are "nested" within a package.
  //
  // This allows the watcher to optimize and avoid duplicate events.
  List<String> _nestedPaths(BuildPackage rootPackage) {
    return _buildPackages.allPackages.values
        .where((buildPackage) {
          return buildPackage.path.length > rootPackage.path.length &&
              buildPackage.path.startsWith(rootPackage.path);
        })
        .map(
          (buildPackage) =>
              buildPackage.path.substring(rootPackage.path.length + 1) +
              Platform.pathSeparator,
        )
        .toList();
  }
}
