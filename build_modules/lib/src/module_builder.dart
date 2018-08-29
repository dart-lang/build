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
import 'platform.dart';

/// The extension for serialized module assets.
String moduleExtension(DartPlatform platform) => '.${platform.name}.module';

/// A [Resource] that provides a [_CleanMetaModuleCache].
final _cleanMetaModules = Resource<_CleanMetaModuleCache>(
    () => _CleanMetaModuleCache(),
    dispose: (c) => c.dispose());

/// Safely caches deserialized [MetaModule] objects by their [AssetId].
///
/// Tracks access to assets via [BuildStep.canRead] calls.
class _CleanMetaModuleCache {
  final _modules = <AssetId, Future<Result<MetaModule>>>{};

  void dispose() => _modules.clear();

  Future<MetaModule> find(
      DartPlatform platform, String package, AssetReader reader) async {
    var cleanMetaAsset =
        AssetId(package, 'lib/${metaModuleCleanExtension(platform)}');
    if (!await reader.canRead(cleanMetaAsset)) return null;
    var metaResult = _modules.putIfAbsent(
        cleanMetaAsset,
        () => Result.capture(reader.readAsString(cleanMetaAsset).then((c) =>
            MetaModule.fromJson(jsonDecode(c) as Map<String, dynamic>))));
    return Result.release(metaResult);
  }
}

/// Creates `.module` files for any `.dart` file that is the primary dart
/// source of a [Module].
class ModuleBuilder implements Builder {
  final DartPlatform _platform;

  ModuleBuilder(this._platform)
      : buildExtensions = {
          '.dart': [moduleExtension(_platform)]
        };

  @override
  final Map<String, List<String>> buildExtensions;

  @override
  Future build(BuildStep buildStep) async {
    var cleanMetaModules = await buildStep.fetchResource(_cleanMetaModules);
    var metaModule = await cleanMetaModules.find(
        _platform, buildStep.inputId.package, buildStep);
    final outputModule = metaModule.modules.firstWhere(
        (m) => m.primarySource == buildStep.inputId,
        orElse: () => null);
    if (outputModule == null) return;
    await buildStep.writeAsString(
        buildStep.inputId.changeExtension(moduleExtension(_platform)),
        jsonEncode(outputModule.toJson()));
  }
}
