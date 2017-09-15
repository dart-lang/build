// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:scratch_space/scratch_space.dart';

/// A shared [ScratchSpace] for ddc and analyzer workers that persists during
/// individual builds.
final scratchSpaceResource = new Resource<ScratchSpace>(
    () => new ScratchSpace(),
    dispose: (old) => old.delete());
