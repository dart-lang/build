// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'pubspecs.dart';

/// The current package path, workspace path, and whether to build the single
/// package or the workspace.
class BuildPaths {
  /// The package in which `build_runner` was launched.
  ///
  /// Might be the root of a workspace, which can also be built like a package.
  final String packagePath;

  /// The workspace in which `build_runner` was launched, if any.
  final String? workspacePath;

  /// Whether this build should build the whole workspace.
  ///
  /// Otherwise, just build the package at [packagePath].
  final bool buildWorkspace;

  BuildType get buildType {
    if (workspacePath == null) return BuildType.singlePackage;
    if (buildWorkspace) return BuildType.workspace;
    return BuildType.singlePackageInWorkspace;
  }

  /// The path to the output root for this build.
  ///
  /// If [buildWorkspace] then [workspacePath], otherwise [packagePath].
  String get outputRootPath => buildWorkspace ? workspacePath! : packagePath;

  BuildPaths({
    required this.packagePath,
    required this.buildWorkspace,
    this.workspacePath,
  });

  /// Loads for [packagePath] and user input as to whether to [buildWorkspace].
  ///
  /// If not in a workspace, [buildWorkspace] is forced to `false`.
  static BuildPaths load(String packagePath, {required bool buildWorkspace}) {
    String? workspacePath;
    final workspaceRefFile = File(
      p.join(packagePath, '.dart_tool', 'pub', 'workspace_ref.json'),
    );
    if (workspaceRefFile.existsSync()) {
      // The `workspace_ref.json` might be stale. Confirm by checking the
      // current package `pubspec.yaml`. If it's a package in the workspace then
      // it has `resolution: workspace`, if it is the workspace root then it has
      // `workspace:`.
      final pubspec = Pubspecs.load(p.join(packagePath, 'pubspec.yaml'));
      if (pubspec['resolution'] == 'workspace' ||
          pubspec['workspace'] != null) {
        final workspaceRef =
            (json.decode(workspaceRefFile.readAsStringSync())
                    as Map<String, Object?>)['workspaceRoot']
                as String;
        workspacePath = p.canonicalize(
          p.join(p.dirname(workspaceRefFile.path), workspaceRef),
        );
      }
    }
    return BuildPaths(
      packagePath: packagePath,
      buildWorkspace: buildWorkspace && workspacePath != null,
      workspacePath: workspacePath,
    );
  }
}

/// The type of build: single package, single package in a workspace, or
/// wole workspace build.
enum BuildType { singlePackage, singlePackageInWorkspace, workspace }
