// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:yaml/yaml.dart';

import 'package_layout.dart';
import 'weaver_exception.dart';

/// Finds the package to weave from a directory and the `--package` option.
class PackageLayoutFinder {
  PackageLayoutFinder(Directory currentDirectory)
    : currentDirectory = currentDirectory.absolute;

  final Directory currentDirectory;

  /// The package to weave.
  ///
  /// That is the package containing [currentDirectory]. In a pub workspace it
  /// can instead be named by [packageFlag], relative to the workspace root.
  ///
  /// Throws [WeaverException] if there is none.
  PackageLayout find(String? packageFlag) {
    final packageDir = _enclosingPackage(currentDirectory);
    if (packageDir == null) {
      throw WeaverException(
        'no pubspec.yaml in or above the current directory.',
      );
    }
    final pubspec = _loadPubspec(packageDir);

    final Directory root;
    if (pubspec['workspace'] != null) {
      root = packageDir;
    } else if (pubspec['resolution'] == 'workspace') {
      final workspaceRoot = _enclosingWorkspace(packageDir.parent);
      if (workspaceRoot == null) {
        throw WeaverException(
          '${packageDir.path} has `resolution: workspace` but no workspace '
          'root was found above it.',
        );
      }
      root = workspaceRoot;
    } else {
      if (packageFlag != null) {
        throw WeaverException(
          '--package is only for pub workspaces; ${packageDir.path} is a '
          'standalone package.',
        );
      }
      return PackageLayout.of(root: packageDir.path);
    }

    final member =
        _withoutTrailingSlashes(packageFlag) ??
        _relativeMember(root, packageDir);
    if (member == null) {
      throw WeaverException(
        '${root.path} is a pub workspace; pass --package=DIR or run from '
        'inside a member.',
      );
    }
    final segments = member.split('/');
    if (member.startsWith('/') ||
        segments.any((s) => s.isEmpty || s == '.' || s == '..') ||
        !File('${root.path}/$member/pubspec.yaml').existsSync()) {
      throw WeaverException(
        '--package=$member is not a member directory, relative to the '
        'workspace root ${root.path}.',
      );
    }
    return PackageLayout.of(root: root.path, member: member);
  }

  /// [packageFlag] without trailing slashes.
  static String? _withoutTrailingSlashes(String? packageFlag) {
    if (packageFlag == null) return null;
    var result = packageFlag;
    while (result.length > 1 && result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  /// The nearest directory at or above [dir] with a `pubspec.yaml`.
  static Directory? _enclosingPackage(Directory dir) {
    for (var d = dir.absolute; ; d = d.parent) {
      if (File('${d.path}/pubspec.yaml').existsSync()) return d;
      if (d.path == d.parent.path) return null;
    }
  }

  /// The nearest directory at or above [dir] whose `pubspec.yaml` declares a
  /// workspace.
  static Directory? _enclosingWorkspace(Directory dir) {
    for (var d = dir.absolute; ; d = d.parent) {
      if (File('${d.path}/pubspec.yaml').existsSync() &&
          _loadPubspec(d)['workspace'] != null) {
        return d;
      }
      if (d.path == d.parent.path) return null;
    }
  }

  /// The path of [packageDir] relative to [root], or `null` if [packageDir] is
  /// [root].
  static String? _relativeMember(Directory root, Directory packageDir) {
    final rootPath = root.absolute.path;
    final packagePath = packageDir.absolute.path;
    if (packagePath == rootPath) return null;
    return packagePath.substring(rootPath.length + 1);
  }

  static Map<Object?, Object?> _loadPubspec(Directory dir) {
    final yaml = loadYaml(File('${dir.path}/pubspec.yaml').readAsStringSync());
    return yaml is Map ? yaml : const {};
  }
}
