import 'dart:async';
import 'dart:io';

import 'package:bazel_worker/bazel_worker.dart';
import 'package:build/build.dart';
import 'package:build_barback/build_barback.dart';
import 'package:path/path.dart' as p;
import 'package:protobuf/protobuf.dart';

import '../bazel_codegen.dart';
import 'arg_parser.dart';
import 'assets/asset_filter.dart';
import 'assets/asset_reader.dart';
import 'assets/asset_writer.dart';
import 'errors.dart';
import 'logging.dart';
import 'summaries/summaries.dart';
import 'timing.dart';

typedef List<Phase> PhaseFactory(Options options);

/// Runs builds as a worker.
Future generateAsWorker(
    PhaseFactory phaseFactory, Map<String, String> defaultContent) {
  return new _CodegenWorker(phaseFactory, defaultContent).run();
}

/// Runs in single build mode (not as a worker).
Future generateSingleBuild(PhaseFactory phaseFactory, List<String> args,
    Map<String, String> defaultContent) async {
  var timings = new CodegenTiming()..start();
  IOSinkLogHandle logger;

  var options = _parseOptions(args);

  try {
    logger = await _runPhases(
        phaseFactory(options), options, defaultContent, timings);
  } catch (e, s) {
    stderr.writeln("Dart Codegen failed with:\n$e\n$s");
    exitCode = EXIT_CODE_ERROR;
  }

  if (logger?.errorCount != 0) {
    exitCode = EXIT_CODE_ERROR;
  }
  await logger?.close();
}

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
  final PhaseFactory phaseFactory;
  int numRuns = 0;

  _CodegenWorker(this.phaseFactory, this.defaultContent);

  @override
  Future<WorkResponse> performRequest(WorkRequest request) async {
    IOSinkLogHandle logHandle;
    var options = _parseOptions(request.arguments);
    try {
      numRuns++;
      var timings = new CodegenTiming()..start();

      var bazelRelativeInputs = request.inputs
          .map((input) => _bazelRelativePath(input.path, options.rootDirs));

      // Actually run the phases
      var phases = phaseFactory(options);
      logHandle = await _runPhases(phases, options, defaultContent, timings,
          isWorker: true, validInputs: new Set()..addAll(bazelRelativeInputs));
      var logger = logHandle.logger;
      logger.info(
          'Completed in worker mode, this worker has ran $numRuns builds');
      await logHandle.close();
      var message = _loggerMessage(logHandle, options.logPath);

      var response = new WorkResponse()
        ..exitCode = logHandle.errorCount == 0 ? EXIT_CODE_OK : EXIT_CODE_ERROR;
      if (message.isNotEmpty) response.output = message;
      return response;
    } catch (e, s) {
      await logHandle?.close();
      return new WorkResponse()
        ..exitCode = EXIT_CODE_ERROR
        ..output = "Dart Codegen worker failed with:\n$e\n$s";
    }
  }
}

/// Runs [phases] to generate files using [options].
///
/// The [timings] instance must already be started.
///
/// See one of the functions above for a description of
/// [defaultContent].
Future<IOSinkLogHandle> _runPhases(List<Phase> phases, Options options,
    Map<String, String> defaultContent, CodegenTiming timings,
    {bool isWorker: false, Set<String> validInputs}) async {
  assert(timings.isRunning);

  final srcPaths = await timings.trackOperation('Collecting input srcs', () {
    return new File(options.srcsPath).readAsLines();
  });
  if (srcPaths.isEmpty) {
    throw new CodegenError('No input files to process.');
  }

  final packageMap =
      await timings.trackOperation('Reading package map', () async {
    var lines = await new File(options.packageMapPath).readAsLines();
    return new Map<String, String>.fromIterable(
        lines.map((line) => line.split(':')),
        key: (l) => l[0],
        value: (l) => l[1]);
  });

  final writer = new BazelAssetWriter(options.outDir, packageMap,
      validInputs: validInputs);
  final reader = new BazelAssetReader(
      options.packagePath, options.rootDirs, packageMap,
      assetFilter: new AssetFilter(validInputs, packageMap, writer));
  final srcAssets = timings.trackOperation('Reading input srcs', () {
    return reader
        .loadAssetsByPath(srcPaths)
        .values
        .where((id) => id.path.endsWith(options.inputExtension))
        .toList();
  });

  /// Need to make sure we never print to stdout/stderr in worker mode, since
  /// that is how we are communicating our responses.
  var logHandle = new IOSinkLogHandle.toFile(options.logPath,
      printLevel: options.logLevel, printToStdErr: !options.isWorker);
  var logger = logHandle.logger;

  for (var phase in phases) {
    var inputSrcs =
        srcAssets.where((asset) => asset.path.endsWith(phase.inputExtension));
    Resolvers resolvers;
    List<String> builderArgs;
    if (options.useSummaries) {
      var summaryOptions = new SummaryOptions.fromArgs(options.additionalArgs);
      resolvers = new SummaryResolvers(summaryOptions, packageMap);
      builderArgs = summaryOptions.additionalArgs;
    } else {
      resolvers = const BarbackResolvers();
      builderArgs = options.additionalArgs;
    }
    var builder = phase.builderFactory(builderArgs);

    try {
      await timings.trackOperation(
          'Generating files: ${phase.outputExtensions}',
          () => runBuilder(builder, inputSrcs, reader, writer, resolvers,
              logger: logger));

      await timings.trackOperation(
          'Checking outputs and writing defaults: ${phase.outputExtensions}',
          () async {
        var futures = <Future>[];
        // Check all expected outputs were written or create w/provided default.
        for (var assetId in inputSrcs) {
          for (var extension in phase.outputExtensions) {
            var expectedAssetId = new AssetId(
                assetId.package,
                assetId.path.substring(
                        0, assetId.path.lastIndexOf(phase.inputExtension)) +
                    extension);
            if (writer.assetsWritten.containsKey(expectedAssetId)) continue;

            if (defaultContent.containsKey(extension)) {
              futures.add(writer.writeAsString(
                  new Asset(expectedAssetId, defaultContent[extension])));
            } else {
              logger.warning('Missing expected output $expectedAssetId');
            }
          }
        }
        await Future.wait(futures);
      });
    } catch (e, stack) {
      logger.severe('Caught error during code generation step '
          '$builder on ${options.packagePath}:\n$e\n$stack');
    }

    // Add all output assets to srcAssets after each phase, and cache them in
    // the reader.
    reader.cacheAssets(writer.assetsWritten);
    srcAssets.addAll(writer.assetsWritten.keys);
    validInputs?.addAll(writer.assetsWritten.keys
        .map((id) => p.join(packageMap[id.package], id.path)));

    // And clear the assets out of the writer.
    writer.assetsWritten.clear();
  }

  timings
    ..stop()
    ..writeLogSummary(logger);

  logger.info('Read ${reader.numAssetsReadFromDisk} files from disk');

  return logHandle;
}

/// Parse [Options] from [args].
Options _parseOptions(List<String> args) {
  var options = new Options.parse(args);
  if (options.help) {
    options.printUsage();
    return null;
  }
  return options;
}

/// Writes a [WorkResponse] to stdout in the format that bazel expects.
void writeResponse(WorkResponse response) {
  var responseBuffer = response.writeToBuffer();

  var writer = new CodedBufferWriter();
  writer.writeInt32NoTag(responseBuffer.length);
  writer.writeRawBytes(responseBuffer);

  stdout.add(writer.toBuffer());
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
