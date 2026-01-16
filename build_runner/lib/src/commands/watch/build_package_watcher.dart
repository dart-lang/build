// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:watcher/watcher.dart';

import '../../build_plan/build_package.dart';
import 'asset_change.dart';

Watcher _default(String path) => Watcher(path);

/// Allows watching significant files and directories in a given package.
class BuildPackageWatcher {
  final Watcher Function(String) _strategy;
  final BuildPackage buildPackage;

  /// The actual watcher instance.
  late final Watcher _watcher;
  Watcher get watcher => _watcher;

  /// Creates a new watcher for a [BuildPackage].
  ///
  /// May optionally specify a [watch] strategy, otherwise will attempt a
  /// reasonable default based on the current platform and the type of path
  /// (i.e. a file versus directory).
  BuildPackageWatcher(this.buildPackage, {Watcher Function(String path)? watch})
    : _strategy = watch ?? _default;

  /// Returns a stream of records for assets that change recursively.
  Stream<AssetChange> watch() {
    _watcher = _strategy(buildPackage.path);
    final events = _watcher.events;
    return events.map((e) => AssetChange.fromEvent(buildPackage, e));
  }
}
