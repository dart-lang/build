// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:args/args.dart';

const _persistentWorkerParam = 'persistent_worker';
const _asyncStackTraceParam = 'async-stack-trace';

final _argParser = ArgParser(allowTrailingOptions: true)
  ..addFlag(_persistentWorkerParam,
      negatable: false,
      defaultsTo: false,
      help: 'Whether to run in worker mode')
  ..addFlag(_asyncStackTraceParam,
      negatable: true,
      defaultsTo: false,
      help: 'Whether to capture a chain of async stack traces');

class StartupArgs {
  final bool persistentWorker;
  final bool asyncStackTrace;
  final List<String> buildArgs;

  StartupArgs._(this.persistentWorker, this.asyncStackTrace, this.buildArgs);

  factory StartupArgs.parse(List<String> args) {
    final argResults = _argParser.parse(args);
    final persistentWorker = argResults[_persistentWorkerParam] as bool;
    final asyncStackTrace = argResults[_asyncStackTraceParam] as bool;
    return StartupArgs._(
      persistentWorker,
      asyncStackTrace,
      argResults.rest,
    );
  }
}
