// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

// TODO(davidmorgan): pass state.
// TODO(davidmorgan): handle uncaught errors--in `run` method?
class Runner {
  Future<int> run(List<String> arguments) async {
    final process = await Process.start('dart', [
      '.dart_tool/build/entrypoint/build.dart.dill',
      ...arguments,
    ], mode: ProcessStartMode.inheritStdio);
    return process.exitCode;
  }
}
