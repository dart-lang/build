// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:scratch_space/scratch_space.dart';

import 'workers.dart';

final _logger = new Logger('BuildCompilers');

/// A shared [ScratchSpace] for ddc and analyzer workers that persists
/// throughout builds.
final scratchSpace = new ScratchSpace();

/// A shared [Resource] for a [ScratchSpace], which cleans up the contents of
/// the [ScratchSpace] in dispose, but doesn't delete it entirely.
final scratchSpaceResource = new Resource<ScratchSpace>(() {
  if (!scratchSpace.exists) {
    scratchSpace.tempDir.createSync(recursive: true);
    scratchSpace.exists = true;
  }
  return scratchSpace;
}, dispose: (_) async {
  await for (var entity in scratchSpace.tempDir.list()) {
    await entity.delete(recursive: true);
  }
}, beforeExit: () async {
  // The workers are running inside the scratch space, so wait for them to
  // shut down before deleting it.
  await analyzerWorkersAreDone;
  await dartdevcWorkersAreDone;
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
      await new Future.delayed(new Duration(milliseconds: delayMs));
    }
  }
});
