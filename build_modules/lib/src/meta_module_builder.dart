// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

import 'common.dart';
import 'meta_module.dart';
import 'module_library_builder.dart';

/// The extension for serialized meta module assets.
const metaModuleExtension = '.meta_module.raw';

/// Creates `.meta_module` file for any Dart library.
///
/// This file contains information about the full computed
/// module structure for the package.
class MetaModuleBuilder implements Builder {
  final bool _isCoarse;
  const MetaModuleBuilder({bool isCoarse}) : _isCoarse = isCoarse ?? true;

  factory MetaModuleBuilder.forOptions(BuilderOptions options) {
    return MetaModuleBuilder(
        isCoarse: moduleStrategy(options) == ModuleStrategy.coarse);
  }

  @override
  final buildExtensions = const {
    r'$lib$': [metaModuleExtension]
  };

  @override
  Future build(BuildStep buildStep) async {
    if (!_isCoarse) return;

    var libraryAssets =
        await buildStep.findAssets(Glob('**$moduleLibraryExtension')).toList();
    var metaModule = await MetaModule.forLibraries(buildStep, libraryAssets);
    var id = AssetId(buildStep.inputId.package, 'lib/$metaModuleExtension');
    await buildStep.writeAsString(id, json.encode(metaModule.toJson()));
  }
}
