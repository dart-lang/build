// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:build_config/build_config.dart';
import 'package:build_runner/build_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

const scriptLocation = '.dart_tool/build/build.dart';

Future<Null> ensureBuildScript() async {
  var scriptFile = new io.File(scriptLocation);
  // TODO - how can we invalidate this?
  if (scriptFile.existsSync()) return;
  scriptFile.createSync(recursive: true);
  await scriptFile.writeAsString(await _generateBuildScript());
}

Future<String> _generateBuildScript() async {
  var packageGraph = new PackageGraph.forThisPackage();
  var buildConfigs =
      await Future.wait(packageGraph.orderedPackages.map(_packageBuildConfig));
  var printStatements = buildConfigs
      .where((config) => config.builderDefinitions.isNotEmpty)
      .map((config) => new Reference('print').call([
            literalString('I would run: ${config.packageName} - '
                '${config.builderDefinitions.keys.toList()}')
          ]).statement);
  final library = new File((b) => b.body.addAll([
        new Method.returnsVoid((b) => b
          ..name = 'main'
          ..body = new Block((b) => b..statements.addAll(printStatements)))
      ]));
  final emitter = new DartEmitter();
  return new DartFormatter().format('${library.accept(emitter)}');
}

Future<BuildConfig> _packageBuildConfig(PackageNode package) async =>
    BuildConfig.fromPackageDir(
        await Pubspec.fromPackageDir(package.path), package.path);
