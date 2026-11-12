// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import '../client.dart';

const _buildDaemonPackageName = 'build_daemon';
const _dartToolDirName = '.dart_tool';
const _minSupportedVersion = '4.1.3';
const _packageConfigFileName = 'package_config.json';
const _packagesKey = 'packages';
const _pubDirName = 'pub';
const _pubspecLockFileName = 'pubspec.lock';
const _pubspecYamlFileName = 'pubspec.yaml';
const _resolutionKey = 'resolution';
const _versionKey = 'version';
const _workspaceKey = 'workspace';
const _workspaceRefFileName = 'workspace_ref.json';
const _workspaceResolutionValue = 'workspace';
const _workspaceRootKey = 'workspaceRoot';

/// Checks the workspace `build_daemon` version, if any.
///
/// Throws [VersionSkew] if the version is too old.
Future<void> checkProjectBuildDaemonVersion(String workingDirectory) async {
  final packageRoot = _findPackageRoot(workingDirectory);
  final workspaceRoot = _findWorkspaceRoot(packageRoot);
  final resolvedVersion =
      await _resolveFromPackageConfig(
        packageRoot,
        workspaceRoot: workspaceRoot,
      ) ??
      _resolveFromPubspecLock(packageRoot, workspaceRoot: workspaceRoot);
  if (resolvedVersion == null) return;
  final minVersion = Version.parse(_minSupportedVersion);
  if (resolvedVersion < minVersion) {
    throw VersionSkew(
      'Project resolved build_daemon $resolvedVersion which is incompatible '
      'with client requiring >=$_minSupportedVersion.',
    );
  }
}

Future<Version?> _resolveFromPackageConfig(
  String packageRoot, {
  required String? workspaceRoot,
}) async {
  final packageConfigFile = _findPackageConfigFile(
    packageRoot,
    workspaceRoot: workspaceRoot,
  );
  if (packageConfigFile == null) return null;
  try {
    final packageConfig = await loadPackageConfig(packageConfigFile);
    final package = packageConfig[_buildDaemonPackageName];
    if (package == null) return null;
    final pubspecFile = File(
      p.join(package.root.toFilePath(), _pubspecYamlFileName),
    );
    if (loadYaml(pubspecFile.readAsStringSync()) case {
      _versionKey: final String versionString,
    }) {
      return Version.parse(versionString);
    }
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }
  return null;
}

Version? _resolveFromPubspecLock(
  String packageRoot, {
  required String? workspaceRoot,
}) {
  for (final root in [packageRoot, ?workspaceRoot]) {
    final pubspecLockFile = File(p.join(root, _pubspecLockFileName));
    if (!pubspecLockFile.existsSync()) continue;
    try {
      if (loadYaml(pubspecLockFile.readAsStringSync()) case {
        _packagesKey: {
          _buildDaemonPackageName: {_versionKey: final String versionString},
        },
      }) {
        return Version.parse(versionString);
      }
    } on FileSystemException {
      // Ignore unreadable pubspec.lock and check workspace root if applicable.
    } on FormatException {
      // Ignore malformed pubspec.lock and check workspace root if applicable.
    }
  }
  return null;
}

/// Finds the nearest enclosing package root containing `pubspec.yaml`, or
/// returns [workingDirectory] if no ancestor contains `pubspec.yaml`.
String _findPackageRoot(String workingDirectory) {
  if (File(p.join(workingDirectory, _pubspecYamlFileName)).existsSync()) {
    return workingDirectory;
  }
  final directory = Directory(workingDirectory);
  if (!directory.existsSync()) return workingDirectory;
  var current = directory.absolute;
  while (true) {
    if (File(p.join(current.path, _pubspecYamlFileName)).existsSync()) {
      return current.path;
    }
    final parent = current.parent;
    if (parent.path == current.path) return workingDirectory;
    current = parent;
  }
}

/// Resolves the workspace root for [packageRoot] if it has a
/// `.dart_tool/pub/workspace_ref.json` file or declares
/// `resolution: workspace` in `pubspec.yaml`.
String? _findWorkspaceRoot(String packageRoot) {
  final workspaceRefFile = File(
    p.join(packageRoot, _dartToolDirName, _pubDirName, _workspaceRefFileName),
  );
  if (workspaceRefFile.existsSync()) {
    try {
      if (jsonDecode(workspaceRefFile.readAsStringSync()) case {
        _workspaceRootKey: final String workspaceRef,
      }) {
        return p.canonicalize(
          p.join(p.dirname(workspaceRefFile.path), workspaceRef),
        );
      }
    } on FileSystemException {
      // Fall through to pubspec inspection.
    } on FormatException {
      // Fall through to pubspec inspection.
    }
  }

  final pubspecFile = File(p.join(packageRoot, _pubspecYamlFileName));
  if (!pubspecFile.existsSync()) return null;
  try {
    if (loadYaml(pubspecFile.readAsStringSync()) case {
      _resolutionKey: _workspaceResolutionValue,
    }) {
      var current = Directory(packageRoot).absolute.parent;
      while (true) {
        final parentPubspec = File(p.join(current.path, _pubspecYamlFileName));
        if (parentPubspec.existsSync()) {
          if (loadYaml(parentPubspec.readAsStringSync()) case {
            _workspaceKey: Object _,
          }) {
            return current.path;
          }
        }
        final parent = current.parent;
        if (parent.path == current.path) return null;
        current = parent;
      }
    }
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }
  return null;
}

/// Finds the `package_config.json` for [packageRoot] or its [workspaceRoot].
///
/// Returns `null` on failure to find any `package_config.json`.
File? _findPackageConfigFile(
  String packageRoot, {
  required String? workspaceRoot,
}) {
  for (final root in [?workspaceRoot, packageRoot]) {
    final file = File(p.join(root, _dartToolDirName, _packageConfigFileName));
    if (file.existsSync()) return file;
  }
  return null;
}
