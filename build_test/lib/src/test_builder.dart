// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_config/build_config.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_runner_core/build_runner_core.dart';
// ignore: implementation_imports
import 'package:build_runner_core/src/generate/build_series.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

import 'assets.dart';
import 'in_memory_reader_writer.dart';
import 'test_reader_writer.dart';

AssetId _passThrough(AssetId id) => id;

/// Validates that [actualAssets] matches the expected [outputs].
///
/// The keys in [outputs] should be serialized [AssetId]s in the form
/// `'package|path'`. The values should match the expected content for the
/// written asset and may be a `String` which will match against the utf8
/// decoded bytes, a `List<int>` matching the raw bytes, or a [Matcher] for a
/// `List<int>` of  bytes. For writing a [Matcher] against the `String`
/// contents, you can wrap your [Matcher] in a call to `decodedMatches`.
///
/// [actualAssets] are the IDs that were recorded as written during the build.
///
/// Assets are checked against those that were written to [writer]. If other
/// assets were written through the writer, but not as part of the build
/// process, they will be ignored. Only the IDs in [actualAssets] are checked.
///
/// If assets are written to a location that does not match their logical
/// association to a package pass [mapAssetIds] to translate from the logical
/// location to the actual written location.
///
/// The serialized asset graph asset is ignored.
void checkOutputs(
  Map<String, /*List<int>|String|Matcher<List<int>>*/ Object>? outputs,
  Iterable<AssetId> actualAssets,
  TestReaderWriter writer, {
  AssetId Function(AssetId id) mapAssetIds = _passThrough,
}) {
  var modifiableActualAssets = Set.of(actualAssets);

  // Ignore asset graph.
  modifiableActualAssets.removeWhere((id) => id.path.endsWith(assetGraphPath));

  if (outputs != null) {
    outputs.forEach((serializedId, contentsMatcher) {
      assert(
        contentsMatcher is String ||
            contentsMatcher is List<int> ||
            contentsMatcher is Matcher,
      );

      var assetId = makeAssetId(serializedId);

      // Check that the asset was produced.
      expect(
        modifiableActualAssets,
        contains(assetId),
        reason: 'Builder failed to write asset $assetId',
      );
      modifiableActualAssets.remove(assetId);
      var mappedAssetId = assetId;
      if (!writer.testing.exists(assetId)) {
        // The asset was output but not to the expected location. First try the
        // `mapAssetIds` if one was supplied.
        mappedAssetId = mapAssetIds(assetId);
        if (!writer.testing.exists(mappedAssetId)) {
          // Then try the usual mapping for generated assets.
          mappedAssetId = AssetId(
            (writer as InMemoryAssetReaderWriter).rootPackage,
            '.dart_tool/build/generated/${assetId.package}/${assetId.path}',
          );
        }
        // If neither succeeded then the asset was output but written somewhere
        // unexpected.
        if (!writer.testing.exists(mappedAssetId)) {
          throw StateError(
            'Internal error: "$assetId" was recorded as output, but the file '
            'could not be found. All assets: ${writer.testing.assets}',
          );
        }
      }
      var actual = writer.testing.readBytes(mappedAssetId);
      Object expected;
      if (contentsMatcher is String) {
        expected = utf8.decode(actual);
      } else if (contentsMatcher is List<int>) {
        expected = actual;
      } else if (contentsMatcher is Matcher) {
        expected = actual;
      } else {
        throw ArgumentError(
          'Expected values for `outputs` to be of type '
          '`String`, `List<int>`, or `Matcher`, but got `$contentsMatcher`.',
        );
      }
      expect(
        expected,
        contentsMatcher,
        reason: 'Unexpected content for $assetId in result.outputs.',
      );
    });
    // Check that no extra assets were produced.
    expect(
      modifiableActualAssets,
      isEmpty,
      reason:
          'Unexpected outputs found `$modifiableActualAssets`. '
          'Only expected $outputs',
    );
  }
}

/// Runs [builder] in a test environment.
///
/// Calls [testBuilders] with a single builder, see that method for details.
Future<TestBuilderResult> testBuilder(
  Builder builder,
  Map<String, /*String|List<int>*/ Object> sourceAssets, {
  Set<String>? generateFor,
  bool Function(String assetId)? isInput,
  String? rootPackage,
  Map<String, /*String|List<int>|Matcher<List<int>>*/ Object>? outputs,
  void Function(LogRecord log)? onLog,
  void Function(AssetId, Iterable<AssetId>)? reportUnusedAssetsForInput,
  PackageConfig? packageConfig,
  Resolvers? resolvers,
  TestReaderWriter? readerWriter,
  bool enableLowResourceMode = false,
}) async {
  return testBuilders(
    [builder],
    sourceAssets,
    generateFor: generateFor,
    isInput: isInput,
    rootPackage: rootPackage,
    outputs: outputs,
    onLog: onLog,
    reportUnusedAssetsForInput: reportUnusedAssetsForInput,
    packageConfig: packageConfig,
    resolvers: resolvers,
    readerWriter: readerWriter,
    enableLowResourceMode: enableLowResourceMode,
  );
}

/// Runs [builders] in a test environment.
///
/// The test environment supplies in-memory build [sourceAssets] to the builders
/// under test.
///
/// [outputs] may be optionally provided to verify that the builders
/// produce the expected output, see [checkOutputs] for a full description of
/// the [outputs] map and how to use it. If [outputs] is omitted the only
/// validation this method provides is that the build did not `throw`.
///
/// Either [generateFor] or the [isInput] callback can specify which assets
/// should be given as inputs to the builder. These can be omitted if every
/// asset in [sourceAssets] should be considered an input. [generateFor] is
/// ignored if both [isInput] and [generateFor] are provided.
///
/// Pass [rootPackage] to set the package the build is running in; if not passed
/// explicitly it will be taken from the first asset in [sourceAssets].
///
/// The keys in [sourceAssets] and [outputs] are paths to file assets and the
/// values are file contents. The paths must use the following format:
///
///     PACKAGE_NAME|PATH_WITHIN_PACKAGE
///
/// Where `PACKAGE_NAME` is the name of the package, and `PATH_WITHIN_PACKAGE`
/// is the path to a file relative to the package. `PATH_WITHIN_PACKAGE` must
/// include `lib`, `web`, `bin` or `test`. Example: "myapp|lib/utils.dart".
///
/// Callers may optionally provide an [onLog] callback to do validaiton on the
/// logging output of the builder.
///
/// An optional [packageConfig] may be supplied to set the language versions of
/// certain packages. It will only be used for this purpose and not for reading
/// of files or converting uris.
///
/// Optionally pass [resolvers] to set the analyzer resolvers for the build.
///
/// Enabling of language experiments is supported through the
/// `withEnabledExperiments` method from package:build.
///
/// To mark a builder as optional, add it to [optionalBuilders]. Optional
/// builders only run if their output is used by a non-optional builder.
///
/// The default builder config will be overwritten with one that causes the
/// builder to run for all inputs. To use the default builder config instead,
/// set [testingBuilderConfig] to `false`.
///
/// Optionally pass [readerWriter] to set the filesystem that will be used
/// during the build. Before the build, [sourceAssets] will be written to it.
///
/// Optionally pass [enableLowResourceMode], which acts like the command
/// line flag; in particular it disables file caching.
///
/// Returns a [TestBuilderResult] with the [BuildResult] and the
/// [TestReaderWriter] used for the build, which can be used for further
/// checks.
Future<TestBuilderResult> testBuilders(
  Iterable<Builder> builders,
  Map<String, /*String|List<int>*/ Object> sourceAssets, {
  Set<String>? generateFor,
  bool Function(String assetId)? isInput,
  String? rootPackage,
  Map<String, /*String|List<int>|Matcher<List<int>>*/ Object>? outputs,
  void Function(LogRecord log)? onLog,
  void Function(AssetId, Iterable<AssetId>)? reportUnusedAssetsForInput,
  PackageConfig? packageConfig,
  Resolvers? resolvers,
  Set<Builder> optionalBuilders = const {},
  bool testingBuilderConfig = true,
  TestReaderWriter? readerWriter,
  bool enableLowResourceMode = false,
}) async {
  onLog ??=
      (log) => printOnFailure(
        '$log'
        '${log.error == null ? '' : '  ${log.error}'}'
        '${log.stackTrace == null ? '' : '  ${log.stackTrace}'}',
      );

  var inputIds = {
    for (var descriptor in sourceAssets.keys) makeAssetId(descriptor),
  };

  var allPackages = {for (var id in inputIds) id.package};
  rootPackage ??= allPackages.first;

  readerWriter ??= TestReaderWriter(rootPackage: rootPackage);

  sourceAssets.forEach((serializedId, contents) {
    var id = makeAssetId(serializedId);
    if (contents is String) {
      readerWriter!.testing.writeString(id, contents);
    } else if (contents is List<int>) {
      readerWriter!.testing.writeBytes(id, contents);
    }
  });

  final inputFilter = isInput ?? generateFor?.contains ?? (_) => true;
  inputIds.retainWhere((id) => inputFilter('$id'));

  var logSubscription = Logger.root.onRecord.listen(onLog);
  resolvers ??=
      packageConfig == null && enabledExperiments.isEmpty
          ? AnalyzerResolvers.sharedInstance
          : AnalyzerResolvers.custom(packageConfig: packageConfig);

  // Build a `PackageGraph` based on [sourceAssets].
  final rootNode = PackageNode(
    rootPackage,
    '/$rootPackage',
    DependencyType.path,
    null,
    isRoot: true,
  );
  for (final otherPackage in allPackages.where((p) => p != rootPackage)) {
    rootNode.dependencies.add(
      PackageNode(otherPackage, '/$otherPackage', DependencyType.path, null),
    );
  }
  final packageGraph = PackageGraph.fromRoot(rootNode);

  final environment = BuildEnvironment(
    packageGraph,
    reader: readerWriter,
    writer: readerWriter,
  );

  String builderName(Builder builder) {
    final result = builder.toString();
    if (result.startsWith("Instance of '") && result.endsWith("'")) {
      return result.substring("Instance of '".length, result.length - 1);
    }
    return result;
  }

  final buildOptions = await BuildOptions.create(
    _NoopLogSubscription(),
    packageGraph: packageGraph,
    reportUnusedAssetsForInput: reportUnusedAssetsForInput,
    resolvers: resolvers,
    overrideBuildConfig:
        // Override sources to all inputs, optionally restricted by
        // [inputFilter] or [generateFor]. Or if [testingBuilderConfig] is
        // false, use the defaults. These skip some files, for example
        // picking up `lib/**` but not all files in the package root.
        testingBuilderConfig
            ? {
              for (final package in allPackages)
                package: BuildConfig.fromMap(package, [], {
                  'targets': {
                    package: {
                      'sources': [
                        r'\$package$',
                        r'lib/$lib$',
                        r'test/$test$',
                        r'web/$web$',
                        ...inputIds
                            .where((id) => id.package == package)
                            .map((id) => id.path),
                      ],
                    },
                  },
                }),
            }
            : const {},
    // Tests always trigger the "build script updated" check, even if it
    // didn't change. Skip it to allow testing with preserved state.
    skipBuildScriptCheck: true,
    enableLowResourcesMode: enableLowResourceMode,
  );

  final buildSeries = await BuildSeries.create(buildOptions, environment, [
    for (final builder in builders)
      apply(
        builderName(builder),
        [(_) => builder],
        (package) => package.name != r'$sdk',
        isOptional: optionalBuilders.contains(builder),
      ),
  ], {});

  // Run the build.
  final buildResult = await buildSeries.run({});

  // Do cleanup that would usually happen on process exit.
  await buildSeries.beforeExit();

  // Stop logging.
  await logSubscription.cancel();

  // Check the build outputs as requested.
  checkOutputs(outputs, readerWriter.testing.assetsWritten, readerWriter);

  return TestBuilderResult(
    buildResult: buildResult,
    readerWriter: readerWriter,
  );
}

class TestBuilderResult {
  final BuildResult buildResult;
  final TestReaderWriter readerWriter;

  TestBuilderResult({required this.buildResult, required this.readerWriter});
}

/// [LogSubscription] that does nothing.
class _NoopLogSubscription implements LogSubscription {
  @override
  StreamSubscription<LogRecord> get logListener =>
      StreamController<LogRecord>().stream.listen((_) {});
}
