// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:build_runner/build_runner.dart';
import 'package:build_config/build_config.dart';

const scriptLocation = '.dart_tool/build/build.dart';

Future<Null> ensureBuildScript() async {
  var scriptFile = new File(scriptLocation);
  // TODO - how can we invalidate this?
  if (scriptFile.existsSync()) return;
  scriptFile.createSync(recursive: true);
  await scriptFile.writeAsString(await _generateBuildScript());
}

Future<String> _generateBuildScript() async {
  var result = new StringBuffer();
  var packageGraph = new PackageGraph.forThisPackage();
  var buildConfigs =
      await Future.wait(packageGraph.orderedPackages.map(_packageBuildConfig));
  result.writeln('void main() {');
  for (var config in buildConfigs) {
    if (config.builderDefinitions.isNotEmpty) {
      result.writeln('print("I would run: ${config.packageName} - '
          '${config.builderDefinitions.keys.toList()}");');
    }
  }
  result.writeln('}');
  return '$result';
}

Future<BuildConfig> _packageBuildConfig(PackageNode package) async =>
    BuildConfig.fromPackageDir(
        await Pubspec.fromPackageDir(package.path), package.path);
