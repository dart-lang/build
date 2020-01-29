// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This library is patched to work in bazel and is kept intentionally small to
// make the patching more maintainable.
//
// For that reason do not add anything additional to this library without
// very good reason.
library build_resolvers.src.sdk_path;

import 'dart:io';

import 'package:path/path.dart' as p;

/// Path to the running dart's SDK root.
final runningDartSdkPath = p.dirname(p.dirname(Platform.resolvedExecutable));
