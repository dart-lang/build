// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_test/build_test.dart';
// ignore: implementation_imports
import 'package:build_test/src/in_memory_reader_writer.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package_graphs.dart';

Future<void> wait(int milliseconds) =>
    Future.delayed(Duration(milliseconds: milliseconds));

void _printOnFailure(LogRecord record) {
  printOnFailure(
    '$record'
    '${record.error == null ? '' : '  ${record.error}'}'
    '${record.stackTrace == null ? '' : '  ${record.stackTrace}'}',
  );
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
/// [resumeFrom] reuses the `readerWriter` from a previous [BuildResult].
///
/// [packageGraph] supplies the root package into which the outputs are to be
/// written.
///
/// [status] optionally indicates the desired outcome.
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
/// TODO(davidmorgan): this overlaps with the newer `testBuilders` in
/// `package:build_test`, can they be unified?
Future<TestBuildersResult> testPhases(
  List<BuilderApplication> builders,
  Map<String, /*String|List<int>*/ Object> inputs, {
  TestBuildersResult? resumeFrom,
  Map<String, /*String|List<int>*/ Object>? outputs,
  PackageGraph? packageGraph,
  BuildStatus status = BuildStatus.success,
  Map<String, BuildConfig>? overrideBuildConfig,
  Level? logLevel,
  // A better way to "silence" logging than setting logLevel to OFF.
  void Function(LogRecord record) onLog = _printOnFailure,
  bool checkBuildStatus = true,
  bool deleteFilesByDefault = true,
  bool enableLowResourcesMode = false,
  Map<String, Map<String, dynamic>>? builderConfigOverrides,
  bool verbose = false,
  Set<BuildDirectory> buildDirs = const {},
  Set<BuildFilter> buildFilters = const {},
  String? logPerformanceDir,
  String expectedGeneratedDir = 'generated',
  void Function(AssetId id)? onDelete,
}) async {
  packageGraph ??= buildPackageGraph({rootPackage('a'): []});
  var readerWriter =
      resumeFrom == null
          ? TestReaderWriter(rootPackage: packageGraph.root.name)
          : resumeFrom.readerWriter;

  // Cast because this is not part of public `test_builder` API.
  if (onDelete != null) {
    readerWriter = (readerWriter as InMemoryAssetReaderWriter).copyWith(
      onDelete: onDelete,
    );
  }

  var pkgConfigId = AssetId(
    packageGraph.root.name,
    '.dart_tool/package_config.json',
  );
  if (!await readerWriter.canRead(pkgConfigId)) {
    var packageConfig = {
      'configVersion': 2,
      'packages': [
        for (var pkgNode in packageGraph.allPackages.values)
          {
            'name': pkgNode.name,
            'rootUri': pkgNode.path,
            'packageUri': 'lib/',
            'languageVersion': pkgNode.languageVersion.toString(),
          },
      ],
    };
    await readerWriter.writeAsString(pkgConfigId, jsonEncode(packageConfig));
  }

  inputs.forEach((serializedId, contents) {
    var id = makeAssetId(serializedId);
    if (contents is String) {
      readerWriter.testing.writeString(id, contents);
    } else if (contents is List<int>) {
      readerWriter.testing.writeBytes(id, contents);
    }
  });

  builderConfigOverrides ??= const {};
  var environment = BuildEnvironment(
    packageGraph,
    reader: readerWriter,
    writer: readerWriter,
    onLogOverride: onLog,
  );
  var logSubscription = LogSubscription(
    environment,
    verbose: verbose,
    logLevel: logLevel,
  );
  var options = await BuildOptions.create(
    logSubscription,
    deleteFilesByDefault: deleteFilesByDefault,
    packageGraph: packageGraph,
    skipBuildScriptCheck: true,
    overrideBuildConfig: overrideBuildConfig ?? const {},
    enableLowResourcesMode: enableLowResourcesMode,
    logPerformanceDir: logPerformanceDir,
  );

  BuildResult result;
  var build = await BuildRunner.create(
    options,
    environment,
    builders,
    builderConfigOverrides,
    isReleaseBuild: false,
  );
  result = await build.run(
    {},
    buildDirs: buildDirs,
    buildFilters: buildFilters,
  );
  await build.beforeExit();
  await options.logListener.cancel();

  if (checkBuildStatus) {
    checkBuild(
      result,
      outputs: outputs,
      readerWriter: readerWriter,
      status: status,
      rootPackage: packageGraph.root.name,
      expectedGeneratedDir: expectedGeneratedDir,
    );
  }

  return TestBuildersResult(buildResult: result, readerWriter: readerWriter);
}

/// Translates expected outptus which start with `$$` to the build cache and
/// validates the success and outputs of the build.
void checkBuild(
  BuildResult result, {
  Map<String, Object>? outputs,
  required TestReaderWriter readerWriter,
  BuildStatus status = BuildStatus.success,
  String rootPackage = 'a',
  String expectedGeneratedDir = 'generated',
}) {
  expect(result.status, status, reason: '$result');

  final unhiddenOutputs = <String, Object>{};
  final unhiddenAssets = <AssetId>{};
  for (final id in outputs?.keys ?? const <String>[]) {
    if (id.startsWith(r'$$')) {
      final unhidden = id.substring(2);
      unhiddenAssets.add(makeAssetId(unhidden));
      unhiddenOutputs[unhidden] = outputs![id]!;
    } else {
      unhiddenOutputs[id] = outputs![id]!;
    }
  }

  AssetId mapHidden(AssetId id, String expectedGeneratedDir) =>
      unhiddenAssets.contains(id)
          ? AssetId(
            rootPackage,
            '.dart_tool/build/$expectedGeneratedDir/${id.package}/${id.path}',
          )
          : id;

  if (status == BuildStatus.success) {
    checkOutputs(
      unhiddenOutputs,
      result.outputs,
      readerWriter,
      mapAssetIds: (id) => mapHidden(id, expectedGeneratedDir),
    );
  }
}

class TestBuildersResult {
  final BuildResult buildResult;
  final TestReaderWriter readerWriter;

  TestBuildersResult({required this.buildResult, required this.readerWriter});
}
