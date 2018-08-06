// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:io';

import 'package:bazel_worker/bazel_worker.dart';
import 'package:build/build.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:path/path.dart' as p;

import 'args/build_args.dart';
import 'args/builder_options.dart';
import 'assets/asset_filter.dart';
import 'assets/asset_reader.dart';
import 'assets/asset_writer.dart';
import 'errors.dart';
import 'logging.dart';
import 'run_builders.dart';
import 'summaries/summaries.dart';
import 'timing.dart';

/// Runs builds as a worker.
Future generateAsWorker(
    List<BuilderFactory> builders, Map<String, String> defaultContent) {
  return _CodegenWorker(builders, defaultContent).run();
}

/// Runs in single build mode (not as a worker).
Future generateSingleBuild(List<BuilderFactory> builders, List<String> args,
    Map<String, String> defaultContent) async {
  var timings = CodegenTiming()..start();
  IOSinkLogHandle logger;

  var buildArgs = _parseArgs(args);

  try {
    logger = await _runBuilders(builders, buildArgs, defaultContent, timings);
  } catch (e, s) {
    stderr.writeln('Dart Codegen failed with:\n$e\n$s');
    exitCode = EXIT_CODE_ERROR;
  }

  if (logger?.errorCount != 0) {
    exitCode = EXIT_CODE_ERROR;
  }
  await logger?.close();
}

Future<Map<String, String>> _packageMap(
        BuildArgs buildArgs, CodegenTiming timings) =>
    timings.trackOperation('Reading package map', () async {
      var lines = await File(buildArgs.packageMapPath).readAsLines();
      return Map<String, String>.fromIterable(
          lines.map((line) => line.split(':')),
          key: (l) => (l as List<String>)[0],
          value: (l) => (l as List<String>)[1]);
    }) as Future<Map<String, String>>;

String _bazelRelativePath(String inputPath, Iterable<String> outputDirs) {
  for (var outputDir in outputDirs) {
    if (inputPath.startsWith(outputDir)) {
      return p.relative(inputPath, from: outputDir);
    }
  }
  return inputPath;
}

/// Persistent worker loop implementation.
class _CodegenWorker extends AsyncWorkerLoop {
  final Map<String, String> defaultContent;
  final List<BuilderFactory> builders;
  int numRuns = 0;

  _CodegenWorker(this.builders, this.defaultContent);

  @override
  Future<WorkResponse> performRequest(WorkRequest request) async {
    IOSinkLogHandle logHandle;
    var buildArgs = _parseArgs(request.arguments);
    try {
      numRuns++;
      var timings = CodegenTiming()..start();

      var bazelRelativeInputs = request.inputs
          .map((input) => _bazelRelativePath(input.path, buildArgs.rootDirs));

      logHandle = await _runBuilders(
          builders, buildArgs, defaultContent, timings,
          isWorker: true, validInputs: Set()..addAll(bazelRelativeInputs));
      logHandle.logger.info(
          'Completed in worker mode, this worker has ran $numRuns builds');
      await logHandle.close();
      var message = _loggerMessage(logHandle, buildArgs.logPath);

      var response = WorkResponse()
        ..exitCode = logHandle.errorCount == 0 ? EXIT_CODE_OK : EXIT_CODE_ERROR;
      if (message.isNotEmpty) response.output = message;
      return response;
    } catch (e, s) {
      await logHandle?.close();
      return WorkResponse()
        ..exitCode = EXIT_CODE_ERROR
        ..output = 'Dart Codegen worker failed with:\n$e\n$s';
    }
  }
}

/// Sets up resources and runs [builders] then fills in default content.
///
/// When there are multiple builders, the outputs of each are assumed to be
/// primary inputs to the next builder sequentially.
///
/// The [timings] instance must already be started.
Future<IOSinkLogHandle> _runBuilders(
    List<BuilderFactory> builders,
    BuildArgs buildArgs,
    Map<String, String> defaultContent,
    CodegenTiming timings,
    {bool isWorker = false,
    Set<String> validInputs}) async {
  assert(timings.isRunning);

  final srcPaths = await timings.trackOperation('Collecting input srcs', () {
    return File(buildArgs.srcsPath).readAsLines();
  });
  if (srcPaths.isEmpty) {
    throw CodegenError('No input files to process.');
  }
  final packageMap = await _packageMap(buildArgs, timings);

  final packageName = packageMap.keys
      .firstWhere((name) => packageMap[name] == buildArgs.packagePath);
  final writer =
      BazelAssetWriter(buildArgs.outDir, packageMap, validInputs: validInputs);
  final reader = BazelAssetReader(packageName, buildArgs.rootDirs, packageMap,
      assetFilter: AssetFilter(validInputs, packageMap));
  var logHandle = IOSinkLogHandle.toFile(buildArgs.logPath,
      printLevel: buildArgs.logLevel, printToStdErr: !buildArgs.isWorker);
  Resolvers resolvers;
  List<String> builderArgs;
  if (buildArgs.useSummaries) {
    var summaryOptions = SummaryOptions.fromArgs(buildArgs.additionalArgs);
    resolvers = SummaryResolvers(summaryOptions, packageMap);
    builderArgs = summaryOptions.additionalArgs;
  } else {
    resolvers = AnalyzerResolvers();
    builderArgs = buildArgs.additionalArgs;
  }
  await runBuilders(
      builders,
      buildArgs.packagePath,
      buildArgs.buildExtensions,
      defaultContent,
      srcPaths,
      packageMap,
      timings,
      writer,
      reader,
      logHandle.logger,
      resolvers,
      optionsFromArgs(builderArgs),
      isWorker: isWorker,
      validInputs: validInputs);
  return logHandle;
}

/// Parse [BuildArgs] from [args].
BuildArgs _parseArgs(List<String> args) {
  var buildArgs = BuildArgs.parse(args);
  if (buildArgs.help) {
    buildArgs.printUsage();
    return null;
  }
  return buildArgs;
}

/// Builds a message about warnings/errors given a [IOSinkLogHandle].
String _loggerMessage(IOSinkLogHandle logger, String logPath) {
  if (logger.printedMessages.isNotEmpty) {
    return '\nCompleted with ${logger.errorCount} error(s) and '
        '${logger.warningCount} warning(s):\n\n'
        '${logger.printedMessages.join('\n')}\n\n'
        'See $logPath for additional details if this was a local build, or '
        'enable more verbose logging using the following flag: '
        '`--define=DART_CODEGEN_LOG_LEVEL=(fine|info|warn|error)`.';
  }
  return '';
}
