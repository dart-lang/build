// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';

import 'module_library.dart';

const moduleLibraryExtension = '.module.library';

/// Creates `.module.library` assets listing the dependencies and parts for a
/// Dart library, as well as whether it is an entrypoint.
///
///
/// The output format is determined by [ModuleLibrary.serialize] and can be
/// restored by [ModuleLibrary.deserialize].
///
/// Non-importable Dart source files will not get a `.module.library` asset
/// output. See [ModuleLibrary.isImportable].
class ModuleLibraryBuilder implements Builder {
  const ModuleLibraryBuilder();

  @override
  final buildExtensions = const {
    '.dart': [moduleLibraryExtension]
  };

  @override
  Future build(BuildStep buildStep) async {
    final library = ModuleLibrary.fromSource(
        buildStep.inputId, await buildStep.readAsString(buildStep.inputId));
    if (!library.isImportable) return;
    await buildStep.writeAsString(
        buildStep.inputId.changeExtension(moduleLibraryExtension),
        library.serialize());
  }
}
