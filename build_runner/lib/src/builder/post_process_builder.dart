// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

/// A builder that runs at the end of the build.
abstract class PostProcessBuilder {
  Map<String, List<Glob>> buildExtensions;

  FutureOr<Null> build(PostProcessBuildStep buildStep);
}

abstract class PostProcessBuildStep implements AssetWriter {
  AssetId get input;

  Future<String> readInputAsString();
  Future<List<int>> readInputAsBytes();

  void deleteInput();
}
