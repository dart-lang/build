// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import 'example.dart';

/// Supports `package:build_runner` creation and configuration.
///
/// Not meant to be invoked by hand-authored code.
Builder copyBuilder(BuilderOptions options) {
  return new CopyBuilder();
}
