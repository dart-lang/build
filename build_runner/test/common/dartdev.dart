// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:io/io.dart';
import 'package:path/path.dart' as p;

/// Snapshots of `build_runner` made by `dart run`, shared between workspaces.
///
/// `dart run build_runner` in a new workspace spends about 5s compiling
/// `build_runner` into `.dart_tool/dartdev`. The snapshot depends only on the
/// SDK and on the `build_runner` sources, which are the same for every
/// workspace, so it is copied into each new workspace before the first run.
/// `dart run` checks the snapshot against its depfile and SDK version and
/// recompiles if it is stale; a newer snapshot is then shared again.
class Dartdev {
  /// The directory holding the packages that commands run in.
  final Directory workspace;

  /// The `.dart_tool/dartdev` copy shared between workspaces.
  final Directory shared;

  Dartdev({required this.workspace, required this.shared});

  /// Copies [shared] into the workspace if [commandLine] runs `build_runner`
  /// in [directory] and there is no snapshot there yet.
  void seed(String directory, String commandLine) {
    if (!_runsBuildRunner(commandLine)) return;
    final target = _dartdevDirectory(directory);
    if (target == null || target.existsSync()) return;
    if (!shared.existsSync()) return;
    _copyDirectoryAtomically(shared, target);
  }

  /// Copies the snapshot used in [directory] to [shared] if it is newer.
  void share(String directory, String commandLine) {
    if (!_runsBuildRunner(commandLine)) return;
    final source = _dartdevDirectory(directory);
    if (source == null || !source.existsSync()) return;
    if (shared.existsSync() &&
        !_newestModified(source).isAfter(_newestModified(shared))) {
      return;
    }
    _copyDirectoryAtomically(source, shared);
  }

  static bool _runsBuildRunner(String commandLine) =>
      commandLine.startsWith('dart run build_runner');

  /// The `.dart_tool/dartdev` that `dart run` uses in [directory], or `null`
  /// if [directory] is not in a package.
  ///
  /// That is in the package's own `.dart_tool`, or in the workspace root's
  /// if the package has `resolution: workspace`. It must be found from the
  /// pubspecs: before the first `dart run`, there is no `.dart_tool` yet.
  Directory? _dartdevDirectory(String directory) {
    var current = p.normalize(p.join(workspace.path, directory));
    while (p.equals(current, workspace.path) ||
        p.isWithin(workspace.path, current)) {
      final pubspec = File(p.join(current, 'pubspec.yaml'));
      if (pubspec.existsSync() &&
          !pubspec.readAsLinesSync().any(
            (line) => line.trim() == 'resolution: workspace',
          )) {
        return Directory(p.join(current, '.dart_tool', 'dartdev'));
      }
      current = p.dirname(current);
    }
    return null;
  }

  /// Copies [source] to [target] via a temp directory and a rename, so that
  /// concurrent tests see either the old or the new directory.
  ///
  /// The copy is only an optimization: on failure, it is skipped.
  static void _copyDirectoryAtomically(Directory source, Directory target) {
    final temp = Directory(
      '${target.path}.tmp-$pid-${DateTime.now().microsecondsSinceEpoch}',
    );
    try {
      copyPathSync(source.path, temp.path);
      if (target.existsSync()) target.deleteSync(recursive: true);
      temp.renameSync(target.path);
    } on FileSystemException {
      try {
        if (temp.existsSync()) temp.deleteSync(recursive: true);
      } on FileSystemException {
        // Best effort.
      }
    }
  }

  static DateTime _newestModified(Directory directory) {
    var result = DateTime.fromMillisecondsSinceEpoch(0);
    for (final file in directory.listSync(recursive: true).whereType<File>()) {
      final modified = file.lastModifiedSync();
      if (modified.isAfter(result)) result = modified;
    }
    return result;
  }
}
