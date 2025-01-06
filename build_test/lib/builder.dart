// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import 'src/debug_test_builder.dart';
import 'src/test_bootstrap_builder.dart';

export 'src/debug_test_builder.dart' show DebugTestBuilder;
export 'src/test_bootstrap_builder.dart' show TestBootstrapBuilder;

DebugTestBuilder debugTestBuilder(BuilderOptions _) => const DebugTestBuilder();
DebugIndexBuilder debugIndexBuilder(BuilderOptions _) =>
    const DebugIndexBuilder();
TestBootstrapBuilder testBootstrapBuilder(BuilderOptions _) =>
    TestBootstrapBuilder();
