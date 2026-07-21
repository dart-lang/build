// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['presubmit-only'])
@OnPlatform({'windows': Skip('line endings are different')})
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('ensure local build succeeds with no changes to .g.dart files', () {
    final tempDir = Directory.systemTemp.createTempSync('build_test_');
    addTearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    // `build_runner` doesn't verify outputs in an incremental build, so force
    // a clean build by deleting the cache.
    final buildCacheDir = Directory(p.join('.dart_tool', 'build'));
    if (buildCacheDir.existsSync()) {
      buildCacheDir.deleteSync(recursive: true);
    }

    final result = Process.runSync('dart', [
      'run',
      'build_runner',
      'build',
      '--output=${tempDir.path}',
    ]);
    if (result.exitCode != 0) {
      fail('build_runner failed: ${result.stdout}${result.stderr}');
    }

    final libDirectory = Directory('lib');
    final partPaths = _findGeneratedFiles(libDirectory);

    final outputLibDirectory = Directory(
      p.join(tempDir.path, 'packages', 'build_web_compilers'),
    );
    final outputPartPaths = _findGeneratedFiles(outputLibDirectory);

    expect(outputPartPaths, partPaths);

    for (var i = 0; i < partPaths.length; i++) {
      final partPath = p.join(libDirectory.path, partPaths[i]);
      final outputPartPath = p.join(outputLibDirectory.path, partPaths[i]);
      final content = File(partPath).readAsStringSync();
      final outputContent = File(outputPartPath).readAsStringSync();
      expect(outputContent, content, reason: 'Change to $partPath.');
    }
  });
}

List<String> _findGeneratedFiles(Directory dir) {
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.g.dart'))
      .map((f) => p.relative(f.path, from: dir.path))
      .toList()
    ..sort();
}
