// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:logging/logging.dart';

class BuildLogger {
  Future<T> runAsyncWithLogger<T>(Logger? logger, Future<T> Function() function) async {
    return await function();
  }

  Future<T> stage<T>(BuildStage stage, Future<T> Function() function) async {
    print(stage);
    final stopwatch = Stopwatch()..start();
    final result = await function();
    print('done $stage, ${stopwatch.elapsed}');
    return result;
  }

  void fine(String message) {
    print(message);
  }

void info(String message) {
    print(message);
  }

  void warning(String message) {
    print(message);
  }

  void severe(String message, [Object? e, StackTrace? s]) {
    print(message);
  }
}

enum BuildStage {
generateBuildScript,
precompileBuildScript,
readAssetGraph,
checkForUpdates,
newAssetGraph,
initialBuildCleanup,
updateAssetGraph,
build,
saveGraph,
writePerformance,
}
