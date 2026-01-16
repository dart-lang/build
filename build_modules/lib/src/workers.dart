// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' show min;

import 'package:bazel_worker/driver.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import 'common.dart';
import 'frontend_server_driver.dart';
import 'scratch_space.dart';

/// Completes once the dartdevk workers have been shut down.
Future<void> get dartdevkWorkersAreDone =>
    _dartdevkWorkersAreDoneCompleter?.future ?? Future.value();
Completer<void>? _dartdevkWorkersAreDoneCompleter;

/// Completes once the common frontend workers have been shut down.
Future<void> get frontendWorkersAreDone =>
    _frontendWorkersAreDoneCompleter?.future ?? Future.value();
Completer<void>? _frontendWorkersAreDoneCompleter;

final int _defaultMaxWorkers = min((Platform.numberOfProcessors / 2).ceil(), 4);

const _maxWorkersEnvVar = 'BUILD_MAX_WORKERS_PER_TASK';

final int maxWorkersPerTask = () {
  final toParse =
      Platform.environment[_maxWorkersEnvVar] ?? '$_defaultMaxWorkers';
  final parsed = int.tryParse(toParse);
  if (parsed == null) {
    log.warning(
      'Invalid value for $_maxWorkersEnvVar environment variable, '
      'expected an int but got `$toParse`. Falling back to default value '
      'of $_defaultMaxWorkers.',
    );
    return _defaultMaxWorkers;
  }
  return parsed;
}();

/// Manages a shared set of persistent dartdevk workers.
BazelWorkerDriver get _dartdevkDriver {
  _dartdevkWorkersAreDoneCompleter ??= Completer<void>();
  return __dartdevkDriver ??= BazelWorkerDriver(
    () => Process.start(p.join(sdkDir, 'bin', 'dart'), [
      p.join(sdkDir, 'bin', 'snapshots', 'dartdevc.dart.snapshot'),
      '--persistent_worker',
    ], workingDirectory: scratchSpace.tempDir.path),
    maxWorkers: maxWorkersPerTask,
  );
}

BazelWorkerDriver? __dartdevkDriver;

/// Resource for fetching the current [BazelWorkerDriver] for dartdevk.
final dartdevkDriverResource = Resource<BazelWorkerDriver>(
  () => _dartdevkDriver,
  beforeExit: () async {
    await __dartdevkDriver?.terminateWorkers();
    _dartdevkWorkersAreDoneCompleter?.complete();
    _dartdevkWorkersAreDoneCompleter = null;
    __dartdevkDriver = null;
  },
);

/// Manages a shared set of persistent common frontend workers.
BazelWorkerDriver get _frontendDriver {
  _frontendWorkersAreDoneCompleter ??= Completer<void>();
  return __frontendDriver ??= BazelWorkerDriver(
    () => Process.start(
      p.join(sdkDir, 'bin', 'dartaotruntime'),
      [
        p.join(sdkDir, 'bin', 'snapshots', 'kernel_worker_aot.dart.snapshot'),
        '--persistent_worker',
      ],
      workingDirectory: scratchSpace.tempDir.path,
    ),
    maxWorkers: maxWorkersPerTask,
  );
}

BazelWorkerDriver? __frontendDriver;

/// Resource for fetching the current [BazelWorkerDriver] for common frontend.
final frontendDriverResource = Resource<BazelWorkerDriver>(
  () => _frontendDriver,
  beforeExit: () async {
    await __frontendDriver?.terminateWorkers();
    _frontendWorkersAreDoneCompleter?.complete();
    _frontendWorkersAreDoneCompleter = null;
    __frontendDriver = null;
  },
);

/// Completes once the Frontend Service proxy workers have been shut down.
Future<void> get frontendServerProxyWorkersAreDone =>
    _frontendServerProxyWorkersAreDoneCompleter?.future ?? Future.value();
Completer<void>? _frontendServerProxyWorkersAreDoneCompleter;

FrontendServerProxyDriver get _frontendServerProxyDriver {
  _frontendServerProxyWorkersAreDoneCompleter ??= Completer<void>();
  return __frontendServerProxyDriver ??= FrontendServerProxyDriver();
}

FrontendServerProxyDriver? __frontendServerProxyDriver;

/// Manages a shared set of workers that proxy requests to a single
/// [persistentFrontendServerResource].
final frontendServerProxyDriverResource = Resource<FrontendServerProxyDriver>(
  () async => _frontendServerProxyDriver,
  beforeExit: () async {
    _frontendServerProxyWorkersAreDoneCompleter?.complete();
    await __frontendServerProxyDriver?.terminate();
    _frontendServerProxyWorkersAreDoneCompleter = null;
    __frontendServerProxyDriver = null;
  },
);

PersistentFrontendServer? __persistentFrontendServer;

/// Manages a single persistent instance of the Frontend Server targeting DDC.
final persistentFrontendServerResource = Resource<PersistentFrontendServer>(
  () async =>
      __persistentFrontendServer ??= await PersistentFrontendServer.start(
        sdkRoot: sdkDir,
        fileSystemRoot: scratchSpace.tempDir.uri,
        packagesFile: scratchSpace.tempDir.uri.resolve(packagesFilePath),
      ),
  beforeExit: () async {
    await __persistentFrontendServer?.shutdown();
    __persistentFrontendServer = null;
  },
);
