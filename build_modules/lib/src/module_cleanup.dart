// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';

class ModuleCleanup implements PostProcessBuilder {
  const ModuleCleanup();

  @override
  FutureOr<Null> build(PostProcessBuildStep buildStep) {
    buildStep.deletePrimaryInput();
    return null;
  }

  @override
  final inputExtensions = const [
    '.meta_module.raw',
    '.meta_module.clean',
    '.module',
    '.linked.sum',
    '.unlinked.sum'
  ];
}
