// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:build_runner_core/build_runner_core.dart';
import 'package:frontend_server_client/frontend_server_client.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:stack_trace/stack_trace.dart';

import 'build_script_generate.dart';

final _logger = Logger('Bootstrap');

/// Generates the build script, precompiles it if needed, and runs it.
///
/// The [handleUncaughtError] function will be invoked when the build script
/// terminates with an uncaught error.
///
/// Will retry once on [IsolateSpawnException]s to handle SDK updates.
///
/// Returns the exit code from running the build script.
///
/// If an exit code of 75 is returned, this function should be re-ran.
Future<int> generateAndRun(
  List<String> args, {
  List<String>? experiments,
  Logger? logger,
  Future<String> Function() generateBuildScript = generateBuildScript,
  void Function(Object error, StackTrace stackTrace) handleUncaughtError =
      _defaultHandleUncaughtError,
}) async {
  experiments ??= [];
  logger ??= _logger;
  ReceivePort? exitPort;
  ReceivePort? errorPort;
  ReceivePort? messagePort;
  StreamSubscription? errorListener;
  int? scriptExitCode;

  var tryCount = 0;
  var succeeded = false;
  while (tryCount < 2 && !succeeded) {
    tryCount++;
    exitPort?.close();
    errorPort?.close();
    messagePort?.close();
    await errorListener?.cancel();

    try {
      var buildScript = File(scriptLocation);
      var oldContents = '';
      if (buildScript.existsSync()) {
        oldContents = buildScript.readAsStringSync();
      }
      var newContents = await generateBuildScript();
      // Only trigger a build script update if necessary.
      if (newContents != oldContents) {
        buildScript
          ..createSync(recursive: true)
          ..writeAsStringSync(newContents);
      }
    } on CannotBuildException {
      return ExitCode.config.code;
    }

    scriptExitCode = await _createKernelIfNeeded(logger, experiments);
    if (scriptExitCode != 0) return scriptExitCode!;

    exitPort = ReceivePort();
    errorPort = ReceivePort();
    messagePort = ReceivePort();
    errorListener = errorPort.listen((e) {
      e = e as List<Object?>;
      final error = e[0] ?? TypeError();
      final trace = Trace.parse(e[1] as String? ?? '').terse;

      handleUncaughtError(error, trace);
      if (scriptExitCode == 0) scriptExitCode = 1;
    });
    try {
      await Isolate.spawnUri(
        Uri.file(p.absolute(scriptKernelLocation)),
        args,
        messagePort.sendPort,
        errorsAreFatal: true,
        onExit: exitPort.sendPort,
        onError: errorPort.sendPort,
      );
      succeeded = true;
    } on IsolateSpawnException catch (e) {
      if (tryCount > 1) {
        logger.severe(
          'Failed to spawn build script after retry. '
          'This is likely due to a misconfigured builder definition. '
          'See the generated script at $scriptLocation to find errors.',
          e,
        );
        messagePort.sendPort.send(ExitCode.config.code);
        exitPort.sendPort.send(null);
      } else {
        logger.warning(
          'Error spawning build script isolate, this is likely due to a Dart '
          'SDK update. Deleting precompiled script and retrying...',
        );
      }
      await File(scriptKernelLocation).rename(scriptKernelCachedLocation);
    }
  }

  StreamSubscription? exitCodeListener;
  exitCodeListener = messagePort!.listen((isolateExitCode) {
    if (isolateExitCode is int) {
      scriptExitCode = isolateExitCode;
    } else {
      throw StateError(
        'Bad response from isolate, expected an exit code but got '
        '$isolateExitCode',
      );
    }
    exitCodeListener!.cancel();
    exitCodeListener = null;
  });
  await exitPort?.first;
  await errorListener?.cancel();
  await exitCodeListener?.cancel();

  return scriptExitCode ?? 1;
}

/// Creates a precompiled Kernel snapshot for the build script if necessary.
///
/// A snapshot is generated if:
///
/// - It doesn't exist currently
/// - Either build_runner or build_daemon point at a different location than
///   they used to, see https://github.com/dart-lang/build/issues/1929.
///
/// Returns zero for success or a number for failure which should be set to the
/// exit code.
Future<int> _createKernelIfNeeded(
  Logger logger,
  List<String> experiments,
) async {
  var assetGraphFile = File(assetGraphPathFor(scriptKernelLocation));
  var kernelFile = File(scriptKernelLocation);
  var kernelCacheFile = File(scriptKernelCachedLocation);

  if (await kernelFile.exists()) {
    // If we failed to serialize an asset graph for the snapshot, then we don't
    // want to re-use it because we can't check if it is up to date.
    if (!await assetGraphFile.exists()) {
      await kernelFile.rename(scriptKernelCachedLocation);
      logger.warning(
        'Invalidated precompiled build script due to missing asset graph.',
      );
    } else if (!await _checkImportantPackageDepsAndExperiments(experiments)) {
      await kernelFile.rename(scriptKernelCachedLocation);
      logger.warning(
        'Invalidated precompiled build script due to core package update',
      );
    }
  }

  if (!await kernelFile.exists()) {
    final client = await FrontendServerClient.start(
      scriptLocation,
      scriptKernelCachedLocation,
      'lib/_internal/vm_platform_strong.dill',
      enabledExperiments: experiments,
      printIncrementalDependencies: false,
      packagesJson: (await Isolate.packageConfig)!.toFilePath(),
    );

    var hadOutput = false;
    var hadErrors = false;
    await logTimedAsync(logger, 'Precompiling build script...', () async {
      try {
        final result = await client.compile();
        hadErrors = result.errorCount > 0 || !(await kernelCacheFile.exists());

        // Note: We're logging all output with a single log call to keep
        // annotated source spans intact.
        final logOutput = result.compilerOutputLines.join('\n');
        if (logOutput.isNotEmpty) {
          hadOutput = true;
          if (hadErrors) {
            // Always show compiler output if there were errors
            logger.warning(logOutput);
          } else {
            logger.fine(logOutput);
          }
        }
      } finally {
        client.kill();
      }
    });

    // For some compilation errors, the frontend inserts an "invalid
    // expression" which throws at runtime. When running those kernel files
    // with an onError receive port, the VM can crash (dartbug.com/45865).
    //
    // In this case we leave the cached kernel file in tact so future compiles
    // are faster, but don't copy it over to the real location.
    if (!hadErrors) {
      await kernelCacheFile.rename(scriptKernelLocation);
      if (hadOutput) {
        logger.info(
          'There was output on stdout while precompiling the build script; run '
          'with `--verbose` to see it (you will need to run a `clean` first to '
          're-generate it).\n',
        );
      }
    }

    if (!await kernelFile.exists()) {
      logger.severe('''
Failed to precompile build script $scriptLocation.
This is likely caused by a misconfigured builder definition.
''');
      return ExitCode.config.code;
    }
    // Create _previousLocationsFile.
    await _checkImportantPackageDepsAndExperiments(experiments);
  }
  return 0;
}

const _importantPackages = ['build_daemon', 'build_runner'];
final _previousLocationsFile = File(
  p.url.join(p.url.dirname(scriptKernelLocation), '.packageLocations'),
);

/// Returns whether the [_importantPackages] are all pointing at same locations
/// from the previous run, and [experiments] are the same as the last run.
///
/// Also updates the [_previousLocationsFile] with the new locations if not.
///
/// This is used to detect potential changes to the user facing api and
/// pre-emptively resolve them by precompiling the build script again, see
/// https://github.com/dart-lang/build/issues/1929.
Future<bool> _checkImportantPackageDepsAndExperiments(
  List<String> experiments,
) async {
  var currentLocations = await Future.wait(
    _importantPackages.map(
      (pkg) => Isolate.resolvePackageUri(
        Uri(scheme: 'package', path: '$pkg/fake.dart'),
      ),
    ),
  );
  var fileContents = currentLocations
      .map((uri) => '$uri')
      .followedBy(experiments)
      .join('\n');

  if (!_previousLocationsFile.existsSync()) {
    _logger.fine('Core package locations file does not exist');
    _previousLocationsFile.writeAsStringSync(fileContents);
    return false;
  }

  if (fileContents != _previousLocationsFile.readAsStringSync()) {
    _logger.fine('Core packages locations have changed');
    _previousLocationsFile.writeAsStringSync(fileContents);
    return false;
  }

  return true;
}

void _defaultHandleUncaughtError(Object error, StackTrace stackTrace) {
  stderr
    ..writeln('\n\nYou have hit a bug in build_runner')
    ..writeln(
      'Please file an issue with reproduction steps at '
      'https://github.com/dart-lang/build/issues\n\n',
    )
    ..writeln(error)
    ..writeln(stackTrace);
}
