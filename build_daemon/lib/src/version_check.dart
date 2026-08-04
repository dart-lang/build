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

/// Checks the workspace `build_daemon` version, if any.
///
/// Throws [VersionSkew] if the version is too old.
Future<void> checkProjectBuildDaemonVersion(String workingDirectory) async {
  final packageConfigFile = _findPackageConfigFile(workingDirectory);
  if (packageConfigFile == null) return;
  Version resolvedVersion;
  try {
    final packageConfig = await loadPackageConfig(packageConfigFile);
    final package = packageConfig['build_daemon']!;
    final pubspecFile = File(p.join(package.root.toFilePath(), 'pubspec.yaml'));
    final pubspecYaml = loadYaml(pubspecFile.readAsStringSync());
    if (pubspecYaml is! Map) return;
    final versionString = pubspecYaml['version'] as String?;
    if (versionString == null) return;
    resolvedVersion = Version.parse(versionString);
  } catch (_) {
    return;
  }
  final minVersion = Version.parse('4.1.3');
  if (resolvedVersion < minVersion) {
    throw VersionSkew(
      'Project resolved build_daemon $resolvedVersion which is incompatible '
      'with client requiring >=4.1.3.',
    );
  }
}

/// Finds the `package_config.json` for [workingDirectory].
///
/// It might be in `.dart_tool` or in the workspace `.dart_tool`.
///
/// Returns `null` on failure to find any `package_config.json`.
File? _findPackageConfigFile(String workingDirectory) {
  var rootPath = workingDirectory;
  final workspaceRefFile = File(
    p.join(workingDirectory, '.dart_tool', 'pub', 'workspace_ref.json'),
  );
  if (workspaceRefFile.existsSync()) {
    try {
      final workspaceRef =
          (jsonDecode(workspaceRefFile.readAsStringSync())
                  as Map<String, dynamic>)['workspaceRoot']
              as String?;
      if (workspaceRef != null) {
        rootPath = p.canonicalize(
          p.join(p.dirname(workspaceRefFile.path), workspaceRef),
        );
      }
    } catch (_) {}
  }
  final file = File(p.join(rootPath, '.dart_tool', 'package_config.json'));
  return file.existsSync() ? file : null;
}
