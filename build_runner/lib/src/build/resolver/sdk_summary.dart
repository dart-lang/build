// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/sdk/build_sdk_summary.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

import '../../bootstrap/build_process_state.dart';
import '../../logging/timed_activities.dart';

/// `true` if the currently running dart was provided by the Flutter SDK.
final isFlutter =
    Platform.version.contains('flutter') || Directory(_dartUiPath).existsSync();

/// Path to the running dart's SDK root.
final _runningDartSdkPath = p.dirname(p.dirname(Platform.resolvedExecutable));

/// Path where the dart:ui package will be found, if executing via the dart
/// binary provided by the Flutter SDK.
final _dartUiPath = p.normalize(
  p.join(_runningDartSdkPath, '..', 'pkg', 'sky_engine', 'lib'),
);

/// Lazily creates a summary of the users SDK and caches it under
/// `.dart_tool/build_resolvers`.
///
/// This is only intended for use in typical dart packages, which must
/// have an already existing `.dart_tool` directory (this is how we
/// validate we are running under a typical dart package and not a custom
/// environment).
Future<String> defaultSdkSummaryGenerator() async {
  final dartToolPath = '.dart_tool';
  if (!await Directory(dartToolPath).exists()) {
    throw StateError(
      'The default analyzer resolver can only be used when the current '
      'working directory is a standard pub package.',
    );
  }

  final cacheDir = p.join(dartToolPath, 'build_resolvers');
  final summaryPath = p.join(cacheDir, 'sdk.sum');
  final depsFile = File('$summaryPath.deps');
  final summaryFile = File(summaryPath);

  final packageConfig = await loadPackageConfigUri(
    Uri.parse(buildProcessState.packageConfigUri),
  );
  Future<String> packagePath(String package) async {
    final libRoot = packageConfig.resolve(Uri.parse('package:$package/'));
    return p.dirname(p.fromUri(libRoot));
  }

  final currentDeps = {
    'sdk': Platform.version,
    for (final package in _packageDepsToCheck)
      package: await packagePath(package),
  };

  final needsRebuild =
      !await summaryFile.exists() ||
      !await depsFile.exists() ||
      !await _checkDeps(depsFile, currentDeps);

  // Generate the summary and version files if necessary.
  if (needsRebuild) {
    await TimedActivity.analyzeSdk.runAsync(() async {
      await Directory(cacheDir).create(recursive: true);
      final tempDir = await Directory(cacheDir).createTemp();
      final tempFile = File(p.join(tempDir.path, p.basename(summaryPath)));
      await tempFile.create();
      final embedderYamlPath =
          isFlutter ? p.join(_dartUiPath, '_embedder.yaml') : null;
      await tempFile.writeAsBytes(
        await buildSdkSummary(
          sdkPath: _runningDartSdkPath,
          resourceProvider: PhysicalResourceProvider.INSTANCE,
          embedderYamlPath: embedderYamlPath,
        ),
      );

      await tempFile.rename(summaryPath);
      await _createDepsFile(depsFile, currentDeps);
      await tempDir.delete();
    });
  }

  return p.absolute(summaryPath);
}

final _packageDepsToCheck = ['analyzer', 'build_runner'];

Future<bool> _checkDeps(
  File versionsFile,
  Map<String, Object?> currentDeps,
) async {
  final previous =
      jsonDecode(await versionsFile.readAsString()) as Map<String, Object?>;

  if (previous.keys.length != currentDeps.keys.length) return false;

  for (final entry in previous.entries) {
    if (entry.value != currentDeps[entry.key]) return false;
  }

  return true;
}

Future<void> _createDepsFile(
  File depsFile,
  Map<String, Object?> currentDeps,
) async {
  await depsFile.create(recursive: true);
  await depsFile.writeAsString(jsonEncode(currentDeps));
}
