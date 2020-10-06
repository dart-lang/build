// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/environment/io_environment.dart';
import 'package:build_runner_core/src/environment/overridable_environment.dart';
import 'package:build_runner_core/src/generate/build_result.dart';
import 'package:build_runner_core/src/generate/build_runner.dart';
import 'package:build_runner_core/src/generate/options.dart';
import 'package:build_runner_core/src/package_graph/apply_builders.dart';
import 'package:build_runner_core/src/package_graph/package_graph.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'in_memory_reader.dart';
import 'in_memory_writer.dart';
import 'package_graphs.dart';

Future wait(int milliseconds) =>
    Future.delayed(Duration(milliseconds: milliseconds));

void _printOnFailure(LogRecord record) {
  printOnFailure('$record');
}

/// Runs [builders] in a test environment.
///
/// The test environment supplies in-memory build [inputs] to the builders under
/// test. [outputs] may be optionally provided to verify that the builders
/// produce the expected output.
///
/// The keys in [inputs] and [outputs] are paths to file assets and the values
/// are file contents. The paths must use the following format:
///
///     PACKAGE_NAME|PATH_WITHIN_PACKAGE
///
/// Where `PACKAGE_NAME` is the name of the package, and `PATH_WITHIN_PACKAGE`
/// is the path to a file relative to the package. `PATH_WITHIN_PACKAGE` must
/// include `lib`, `web`, `bin` or `test`. Example: "myapp|lib/utils.dart".
///
/// When an output is expected in the build cache start the package with `$$`.
/// For example `$$myapp|lib/utils.copy.dart` will check that the generated
/// output was written to the build cache.
///
/// [packageGraph] supplies the root package into which the outputs are to be
/// written.
///
/// [status] optionally indicates the desired outcome.
///
/// [writer] can optionally be provided to capture assets written by the
/// builders (e.g. when [outputs] is not sufficient).
///
/// [logLevel] sets the builder log level and [onLog] can optionally capture
/// build log messages.
///
/// Example:
///
///     main() {
///       test('LineCounterBuilder', () async {
///         var actions = [
///           new BuildAction(new LineCounterBuilder(), 'a', ['lib/utils.dart'])
///         ];
///         await testActions(actions, {
///           'a|lib/utils.dart': '',
///         }, outputs: {
///           'a|lib/utils_linecount.txt': '50',
///         });
///       });
///     }
///
Future<BuildResult> testBuilders(
  List<BuilderApplication> builders,
  Map<String, /*String|List<int>*/ dynamic> inputs, {
  Map<String, /*String|List<int>*/ dynamic> outputs,
  PackageGraph packageGraph,
  BuildStatus status = BuildStatus.success,
  Map<String, BuildConfig> overrideBuildConfig,
  InMemoryRunnerAssetReader reader,
  InMemoryRunnerAssetWriter writer,
  Level logLevel,
  // A better way to "silence" logging than setting logLevel to OFF.
  Function(LogRecord record) onLog = _printOnFailure,
  bool checkBuildStatus = true,
  bool deleteFilesByDefault = true,
  bool enableLowResourcesMode = false,
  Map<String, Map<String, dynamic>> builderConfigOverrides,
  bool verbose = false,
  Set<BuildDirectory> buildDirs,
  Set<BuildFilter> buildFilters,
  String logPerformanceDir,
  String expectedGeneratedDir,
}) async {
  packageGraph ??= buildPackageGraph({rootPackage('a'): []});
  writer ??= InMemoryRunnerAssetWriter();
  reader ??= InMemoryRunnerAssetReader.shareAssetCache(writer.assets,
      rootPackage: packageGraph?.root?.name);
  var pkgConfigId =
      AssetId(packageGraph.root.name, '.dart_tool/package_config.json');
  if (!await reader.canRead(pkgConfigId)) {
    var packageConfig = {
      'configVersion': 2,
      'packages': [
        for (var pkgNode in packageGraph.allPackages.values)
          {
            'name': pkgNode.name,
            'rootUri': pkgNode.path,
            'packageUri': 'lib/',
            'languageVersion': pkgNode.languageVersion.toString()
          },
      ],
    };
    await writer.writeAsString(pkgConfigId, jsonEncode(packageConfig));
  }

  inputs.forEach((serializedId, contents) {
    var id = makeAssetId(serializedId);
    if (contents is String) {
      reader.cacheStringAsset(id, contents);
    } else if (contents is List<int>) {
      reader.cacheBytesAsset(id, contents);
    }
  });

  builderConfigOverrides ??= const {};
  var environment = OverrideableEnvironment(IOEnvironment(packageGraph),
      reader: reader, writer: writer, onLog: onLog);
  var logSubscription =
      LogSubscription(environment, verbose: verbose, logLevel: logLevel);
  var options = await BuildOptions.create(logSubscription,
      deleteFilesByDefault: deleteFilesByDefault,
      packageGraph: packageGraph,
      skipBuildScriptCheck: true,
      overrideBuildConfig: overrideBuildConfig,
      enableLowResourcesMode: enableLowResourcesMode,
      logPerformanceDir: logPerformanceDir);

  BuildResult result;
  var build = await BuildRunner.create(
    options,
    environment,
    builders,
    builderConfigOverrides,
    isReleaseBuild: false,
  );
  result =
      await build.run({}, buildDirs: buildDirs, buildFilters: buildFilters);
  await build.beforeExit();
  await options.logListener.cancel();

  if (checkBuildStatus) {
    checkBuild(result,
        outputs: outputs,
        writer: writer,
        status: status,
        rootPackage: packageGraph.root.name,
        expectedGeneratedDir: expectedGeneratedDir);
  }
  return result;
}

/// Translates expected outptus which start with `$$` to the build cache and
/// validates the success and outputs of the build.
void checkBuild(BuildResult result,
    {Map<String, dynamic> outputs,
    InMemoryAssetWriter writer,
    BuildStatus status = BuildStatus.success,
    String rootPackage,
    String expectedGeneratedDir}) {
  expectedGeneratedDir ??= 'generated';
  expect(result.status, status, reason: '$result');

  final unhiddenOutputs = <String, dynamic>{};
  final unhiddenAssets = <AssetId>{};
  for (final id in outputs?.keys ?? const <String>[]) {
    if (id.startsWith(r'$$')) {
      final unhidden = id.substring(2);
      unhiddenAssets.add(makeAssetId(unhidden));
      unhiddenOutputs[unhidden] = outputs[id];
    } else {
      unhiddenOutputs[id] = outputs[id];
    }
  }

  AssetId mapHidden(AssetId id, String expectedGeneratedDir) =>
      unhiddenAssets.contains(id)
          ? AssetId(rootPackage,
              '.dart_tool/build/$expectedGeneratedDir/${id.package}/${id.path}')
          : id;

  if (status == BuildStatus.success) {
    checkOutputs(unhiddenOutputs, result.outputs, writer,
        mapAssetIds: (id) => mapHidden(id, expectedGeneratedDir));
  }
}
