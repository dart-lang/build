// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A `build_runner` command.
abstract interface class BuildRunnerCommand {
  /// Runs the command, returns an exit code indicating success or failure.
  Future<int> run();
}
