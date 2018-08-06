// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:watcher/watcher.dart';

import '../environment/build_environment.dart';
import '../package_graph/apply_builders.dart';
import 'build_impl.dart';
import 'build_result.dart';
import 'options.dart';

class BuildRunner {
  final BuildImpl _build;
  BuildRunner._(this._build);

  Future<Null> beforeExit() => _build.beforeExit();

  Future<BuildResult> run(Map<AssetId, ChangeType> updates) =>
      _build.run(updates);

  static Future<BuildRunner> create(
          BuildOptions options,
          BuildEnvironment environment,
          List<BuilderApplication> builders,
          Map<String, Map<String, dynamic>> builderConfigOverrides,
          {bool isReleaseBuild = false}) async =>
      BuildRunner._(await BuildImpl.create(
          options, environment, builders, builderConfigOverrides,
          isReleaseBuild: isReleaseBuild));
}
