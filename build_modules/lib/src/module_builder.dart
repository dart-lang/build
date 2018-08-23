// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:build/build.dart';

import 'meta_module.dart';
import 'meta_module_clean_builder.dart';
import 'modules.dart';

/// The extension for serialized module assets.
const moduleExtension = '.module';

/// A map of package to corresponding clean [MetaModule].
final _cleanMetaModules = Resource<_CleanMetaModuleCache>(
    () => _CleanMetaModuleCache(),
    dispose: (c) => c.dispose());

class _CleanMetaModuleCache {
  final _modules = <String, Future<Result<MetaModule>>>{};

  void dispose() => _modules.clear();

  Future<MetaModule> find(String packageName, AssetReader reader) async {
    var cleanMetaAsset = AssetId(packageName, 'lib/$metaModuleCleanExtension');
    if (!await reader.canRead(cleanMetaAsset)) return null;
    var metaResult = _modules.putIfAbsent(
        packageName,
        () => Result.capture(reader.readAsString(cleanMetaAsset).then((c) =>
            MetaModule.fromJson(jsonDecode(c) as Map<String, dynamic>))));
    return Result.release(metaResult);
  }
}

/// Creates `.module` files for any `.dart` file that is the primary dart
/// source of a [Module].
class ModuleBuilder implements Builder {
  const ModuleBuilder();

  @override
  final buildExtensions = const {
    '.dart': [moduleExtension]
  };

  @override
  Future build(BuildStep buildStep) async {
    var cleanMetaModules = await buildStep.fetchResource(_cleanMetaModules);
    var metaModule =
        await cleanMetaModules.find(buildStep.inputId.package, buildStep);
    final outputModule = metaModule.modules.firstWhere(
        (m) => m.primarySource == buildStep.inputId,
        orElse: () => null);
    if (outputModule == null) return;
    await buildStep.writeAsString(
        buildStep.inputId.changeExtension(moduleExtension),
        json.encode(outputModule.toJson()));
  }
}
