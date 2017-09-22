// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:stack_trace/stack_trace.dart';

const _foldFramesFor = const [
  '_bazel_codegen',
  'build',
  'build_barback',
  'build_runner',
  'build_test',
];

/// Executes [Trace.foldFrames] removing known `package:build`-packages.
Trace foldInternalFrames(Trace trace) => trace
    .foldFrames((frame) => _foldFramesFor.contains(frame.package), terse: true);
