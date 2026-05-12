// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';

import 'module_library_builder.dart';

class ModuleCleanup implements PostProcessBuilder {
  const ModuleCleanup();

  @override
  void build(PostProcessBuildStep buildStep) {
    buildStep.deletePrimaryInput();
  }

  @override
  final inputExtensions = const [
    moduleLibraryExtension,
    '.meta_module.raw',
    '.meta_module.clean',
    '.module',
  ];
}
