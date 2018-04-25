// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

import 'common.dart';
import 'meta_module.dart';

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
    return new MetaModuleBuilder(
        isCoarse: moduleStrategy(options) == ModuleStrategy.coarse);
  }

  @override
  final buildExtensions = const {
    r'$lib$': const [metaModuleExtension]
  };

  @override
  Future build(BuildStep buildStep) async {
    if (!_isCoarse) return;

    var assets = await buildStep.findAssets(new Glob('**.dart')).toList();
    var metaModule = await MetaModule.forAssets(buildStep, assets);
    var id = new AssetId(buildStep.inputId.package, 'lib/$metaModuleExtension');
    await buildStep.writeAsString(id, json.encode(metaModule.toJson()));
  }
}
