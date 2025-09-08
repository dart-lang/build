// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'src/bootstrap/apply_builders.dart';
import 'src/build_runner.dart' show BuildRunner;

export 'src/commands/daemon/constants.dart' show assetServerPort;

/// Runs `build_runner` with [arguments] and [builders].
///
/// The `build_runner` tool generates a script `.dart_tool/build/entrypoint/build.dart` that
/// depends on the configured builders so it can instantiate them to pass the
/// [builders] parameter.
Future<int> run(List<String> arguments, List<BuilderApplication> builders) =>
    BuildRunner(arguments: arguments, builders: builders).run();
