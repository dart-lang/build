// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'src/build_plan/builder_factories.dart';
import 'src/build_runner.dart' show BuildRunner;

export 'src/commands/daemon/constants.dart' show assetServerPort;

/// Runs `build_runner` with [arguments] and [builderFactories].
///
/// The `build_runner` tool generates a script `.dart_tool/build/entrypoint/build.dart` that
/// depends on the builders so it can pass in [builderFactories].
Future<int> run(List<String> arguments, BuilderFactories builderFactories) =>
    BuildRunner(arguments: arguments, builderFactories: builderFactories).run();
