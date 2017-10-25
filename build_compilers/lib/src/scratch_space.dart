// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:scratch_space/scratch_space.dart';

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
}, beforeExit: () => scratchSpace.delete());
