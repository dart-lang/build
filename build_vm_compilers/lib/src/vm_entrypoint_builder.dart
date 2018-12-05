// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

// ignore: deprecated_member_use
import 'package:analyzer/analyzer.dart';
import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:pool/pool.dart';

import '../builders.dart';

/// Because we hold bytes in memory we don't want to compile to many app entry
/// points at once.
final _buildPool = Pool(16);

/// A builder which combines several [vmKernelModuleExtension] modules into a
/// single [vmKernelEntrypointExtension] file, which represents an entire
/// application.
class VmEntrypointBuilder implements Builder {
  const VmEntrypointBuilder();

  @override
  final buildExtensions = const {
    '.dart': [vmKernelEntrypointExtension],
  };

  @override
  Future<Null> build(BuildStep buildStep) async {
    await _buildPool.withResource(() async {
      var dartEntrypointId = buildStep.inputId;
      var isAppEntrypoint = await _isAppEntryPoint(dartEntrypointId, buildStep);
      if (!isAppEntrypoint) return;

      var moduleId =
          buildStep.inputId.changeExtension(moduleExtension(DartPlatform.vm));
      var module = Module.fromJson(
          json.decode(await buildStep.readAsString(moduleId))
              as Map<String, dynamic>);
      var transitiveModules =
          await module.computeTransitiveDependencies(buildStep);
      var transitiveKernelModules = [
        module.primarySource.changeExtension(vmKernelModuleExtension)
      ].followedBy(transitiveModules.map(
          (m) => m.primarySource.changeExtension(vmKernelModuleExtension)));
      var appContents = <int>[];
      for (var dependencyId in transitiveKernelModules) {
        appContents.addAll(await buildStep.readAsBytes(dependencyId));
      }
      await buildStep.writeAsBytes(
          buildStep.inputId.changeExtension(vmKernelEntrypointExtension),
          appContents);
    });
  }
}

/// Returns whether or not [dartId] is an app entrypoint (basically, whether
/// or not it has a `main` function).
Future<bool> _isAppEntryPoint(AssetId dartId, AssetReader reader) async {
  assert(dartId.extension == '.dart');
  // Skip reporting errors here, dartdevc will report them later with nicer
  // formatting.
  var parsed = parseCompilationUnit(await reader.readAsString(dartId),
      suppressErrors: true);
  // Allow two or fewer arguments so that entrypoints intended for use with
  // [spawnUri] get counted.
  //
  // TODO: This misses the case where a Dart file doesn't contain main(),
  // but has a part that does, or it exports a `main` from another library.
  return parsed.declarations.any((node) {
    return node is FunctionDeclaration &&
        node.name.name == 'main' &&
        node.functionExpression.parameters.parameters.length <= 2;
  });
}
