// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

import 'modules.dart';

/// The extension for serialized module assets.
const moduleExtension = '.module';

/// Creates `.module` files for any `.dart` file that is the primary dart
/// source of a [Module].
class ModuleBuilder implements Builder {
  const ModuleBuilder();

  @override
  final buildExtensions = const {
    '.dart': const [moduleExtension]
  };

  @override
  Future build(BuildStep buildStep) async {
    if (!await buildStep.resolver.isLibrary(buildStep.inputId)) return;

    var library = await buildStep.inputLibrary;
    if (!isPrimary(library)) return;

    var module = new Module.forLibrary(library);

    await buildStep.writeAsString(
        buildStep.inputId.changeExtension(moduleExtension),
        JSON.encode(module.toJson()));
  }
}
