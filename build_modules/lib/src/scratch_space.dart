// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:scratch_space/scratch_space.dart';

import 'workers.dart';

final _logger = Logger('BuildModules');

/// A shared [ScratchSpace] for ddc and analyzer workers that persists
/// throughout builds.
final scratchSpace = ScratchSpace();

/// A shared [Resource] for a [ScratchSpace], which cleans up the contents of
/// the [ScratchSpace] in dispose, but doesn't delete it entirely.
final scratchSpaceResource = Resource<ScratchSpace>(() {
  if (!scratchSpace.exists) {
    scratchSpace.tempDir.createSync(recursive: true);
    scratchSpace.exists = true;
  }
  var packageConfigFile = File(
      p.join(scratchSpace.tempDir.path, '.dart_tool', 'package_config.json'));
  if (!packageConfigFile.existsSync()) {
    var originalConfigFile = File(p.join('.dart_tool', 'package_config.json'));
    var packageConfigContents = _scratchSpacePackageConfig(
        originalConfigFile.readAsStringSync(), originalConfigFile.absolute.uri);
    packageConfigFile
      ..createSync(recursive: true)
      ..writeAsStringSync(packageConfigContents);
  }
  return scratchSpace;
}, beforeExit: () async {
  // The workers are running inside the scratch space, so wait for them to
  // shut down before deleting it.
  await dartdevkWorkersAreDone;
  await frontendWorkersAreDone;
  await dart2jsWorkersAreDone;
  // Attempt to clean up the scratch space. Even after waiting for the workers
  // to shut down we might get file system exceptions on windows for an
  // arbitrary amount of time, so do retries with an exponential backoff.
  var numTries = 0;
  while (true) {
    numTries++;
    if (numTries > 3) {
      _logger
          .warning('Failed to clean up temp dir ${scratchSpace.tempDir.path}.');
      return;
    }
    try {
      // TODO(https://github.com/dart-lang/build/issues/656):  The scratch
      // space throws on `delete` if it thinks it was already deleted.
      // Manually clean up in this case.
      if (scratchSpace.exists) {
        await scratchSpace.delete();
      } else {
        await scratchSpace.tempDir.delete(recursive: true);
      }
      return;
    } on FileSystemException {
      var delayMs = math.pow(10, numTries).floor();
      _logger.info('Failed to delete temp dir ${scratchSpace.tempDir.path}, '
          'retrying in ${delayMs}ms');
      await Future.delayed(Duration(milliseconds: delayMs));
    }
  }
});

/// Modifies all package uris in [rootConfig] to work with the sctrach_space
/// layout. These are uris of the form `../packages/<package-name>`.
///
/// Also modifies the `packageUri` for each package to be empty since the
/// `lib/` directory is hoisted directly into the `packages/<package>`
/// directory.
///
/// Returns the new file contents.
String _scratchSpacePackageConfig(String rootConfig, Uri packageConfigUri) {
  var parsedRootConfig = jsonDecode(rootConfig) as Map<String, dynamic>;
  var version = parsedRootConfig['configVersion'] as int;
  if (version != 2) {
    throw UnsupportedError(
        'Unsupported package_config.json version, got $version but only '
        'version 2 is supported.');
  }
  var packages =
      (parsedRootConfig['packages'] as List).cast<Map<String, dynamic>>();
  var foundRoot = false;
  for (var package in packages) {
    var rootUri = packageConfigUri.resolve(package['rootUri'] as String);
    // We expect to see exactly one package where the root uri is equal to
    // the current directory, and that is the current packge.
    if (rootUri == _currentDirUri) {
      assert(!foundRoot);
      foundRoot = true;
      package['rootUri'] = '../';
      package['packageUri'] = '../packages/${package['name']}/';
    } else {
      package['rootUri'] = '../packages/${package['name']}/';
      package.remove('packageUri');
    }
  }
  if (!foundRoot) {
    _logger.warning('No root package found, this may cause problems for files '
        'not referenced by a package: uri');
  }
  return jsonEncode(parsedRootConfig);
}

final Uri _currentDirUri = Directory.current.uri;
