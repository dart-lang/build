// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
// ignore: implementation_imports
import 'package:build_runner/src/internal.dart';
import 'package:glob/glob.dart';
import 'package:package_config/package_config.dart';

import 'package_reader.dart';
import 'test_builder.dart';
import 'test_reader_writer.dart';

/// Marker constant that may be used in combination with [resolveSources].
///
/// Use of this string means instead of using the contents of the string as the
/// source of a given asset, instead read the file from the default or provided
/// [AssetReader].
const useAssetReader = '__useAssetReader__';

/// A convenience method for using [resolveSources] with a single source file.
Future<T> resolveSource<T>(
  String inputSource,
  FutureOr<T> Function(Resolver resolver) action, {
  AssetId? inputId,
  PackageConfig? packageConfig,
  Set<AssetId>? nonInputsToReadFromFilesystem,
  bool? readAllSourcesFromFilesystem,
  Resolvers? resolvers,
}) {
  inputId ??= AssetId('_resolve_source', 'lib/_resolve_source.dart');
  return _resolveAssets(
    {'${inputId.package}|${inputId.path}': inputSource},
    inputId.package,
    action,
    packageConfig: packageConfig,
    nonInputsToReadFromFilesystem: nonInputsToReadFromFilesystem,
    readAllSourcesFromFilesystem: readAllSourcesFromFilesystem,
    resolverFor: inputId,
    resolvers: resolvers,
  );
}

/// Resolves and runs [action] using a created resolver for [inputs].
///
/// Inputs accepts the pattern of `<package>|<path>.dart`, for example:
/// ```
/// {
///   'test_lib|lib/test_lib.dart': r'''
///     // Contents of test_lib.dart go here.
///   ''',
/// }
/// ```
///
/// You may provide [useAssetReader] as the value of any input in order to read
/// it from the file system instead of being forced to provide it inline as a
/// string. This is useful for mixing real and mocked assets.
///
/// Example use:
/// ```
/// import 'package:build_test/build_test.dart';
/// import 'package:test/test.dart';
///
/// void main() {
///   test('should find a Foo type', () async {
///     var library = await resolveSources({
///       'test_lib|lib/test_lib.dart': r'''
///         library example;
///
///         class Foo {}
///       ''',
///     }, (resolver) => resolver.findLibraryByName('example'));
///     expect(library.getType('Foo'), isNotNull);
///   });
/// }
/// ```
///
/// May provide [resolverFor] to return the [Resolver] for the asset provided,
/// otherwise defaults to the first one in [inputs].
///
/// **NOTE**: All `package` dependencies are resolved using [PackageAssetReader]
/// - by default, [PackageAssetReader.currentIsolate]. A custom [packageConfig]
/// may be provided to map files not visible to the current package's runtime.
///
/// By default, only assets listed in [inputs] with value [useAssetReader] are
/// read from the real filesystem. To read more real files: pass
/// [nonInputsToReadFromFilesystem] for individual files, or
/// [readAllSourcesFromFilesystem] to read all sources available with
/// [packageConfig].
///
/// In packages read using `readAllSourcesFromFilesystem` the asset graph
/// `.dart_tool/build/asset_graph.json` is not loaded as it would cause generated
/// output from the real build to be deleted, in RAM only, by the test build.
///
/// [assetReaderChecks], if provided, runs after the action completes and can be
/// used to add expectations on the reader state.
Future<T> resolveSources<T>(
  Map<String, String> inputs,
  FutureOr<T> Function(Resolver resolver) action, {
  PackageConfig? packageConfig,
  Set<AssetId>? nonInputsToReadFromFilesystem,
  bool? readAllSourcesFromFilesystem,
  String? resolverFor,
  String? rootPackage,
  FutureOr<void> Function(TestReaderWriter)? assetReaderChecks,
  Future<void>? tearDown,
  Resolvers? resolvers,
}) {
  if (inputs.isEmpty) {
    throw ArgumentError.value(inputs, 'inputs', 'Must be a non-empty Map');
  }
  return _resolveAssets(
    inputs,
    rootPackage ?? AssetId.parse(inputs.keys.first).package,
    action,
    packageConfig: packageConfig,
    nonInputsToReadFromFilesystem: nonInputsToReadFromFilesystem,
    readAllSourcesFromFilesystem: readAllSourcesFromFilesystem,
    resolverFor: AssetId.parse(resolverFor ?? inputs.keys.first),
    assetReaderChecks: assetReaderChecks,
    resolvers: resolvers,
  );
}

/// A convenience for using [resolveSources] with a single [inputId] from disk.
Future<T> resolveAsset<T>(
  AssetId inputId,
  FutureOr<T> Function(Resolver resolver) action, {
  PackageConfig? packageConfig,
  Set<AssetId>? nonInputsToReadFromFilesystem,
  bool? readAllSourcesFromFilesystem,
  Future<void>? tearDown,
  Resolvers? resolvers,
}) {
  return _resolveAssets(
    {'${inputId.package}|${inputId.path}': useAssetReader},
    inputId.package,
    action,
    packageConfig: packageConfig,
    nonInputsToReadFromFilesystem: nonInputsToReadFromFilesystem,
    readAllSourcesFromFilesystem: readAllSourcesFromFilesystem,
    resolverFor: inputId,
    resolvers: resolvers,
  );
}

/// Internal-only backing implementation of `resolve{Asset|Source(s)}`.
///
/// If the value of an entry of [inputs] is [useAssetReader] then the value is
/// instead read from the file system, otherwise the provided text is used as
/// the contents of the asset.
Future<T> _resolveAssets<T>(
  Map<String, String> inputs,
  String rootPackage,
  FutureOr<T> Function(Resolver resolver) action, {
  PackageConfig? packageConfig,
  Set<AssetId>? nonInputsToReadFromFilesystem,
  bool? readAllSourcesFromFilesystem,
  AssetId? resolverFor,
  FutureOr<void> Function(TestReaderWriter)? assetReaderChecks,
  Resolvers? resolvers,
}) async {
  final resolvedConfig =
      packageConfig ??
      await loadPackageConfigUri((await Isolate.packageConfig)!);
  final resolveBuilder = _ResolveSourceBuilder(action, resolverFor);

  // Replace any `useAssetReader` inputs with actual values.
  final inputAssetIds = inputs.keys.map(AssetId.parse).toList();
  final assetReader = PackageAssetReader(resolvedConfig, rootPackage);
  for (final assetId in inputAssetIds) {
    final assetValue = inputs[assetId.toString()]!;
    if (assetValue == useAssetReader) {
      inputs[assetId.toString()] = await assetReader.readAsString(assetId);
    }
  }

  final readerWriter = TestReaderWriter(rootPackage: rootPackage);
  // Copy any additionally requested files from the filesystem to `inputs`.
  if (nonInputsToReadFromFilesystem != null) {
    for (final id in nonInputsToReadFromFilesystem) {
      readerWriter.testing.writeBytes(id, await assetReader.readAsBytes(id));
    }
  }
  if (readAllSourcesFromFilesystem == true) {
    for (final package in assetReader.packageConfig.packages) {
      await for (final id in assetReader.findAssets(
        Glob('**'),
        package: package.name,
      )) {
        // Don't read the asset graph from a real build, it would cause
        // generated files from that build to be deleted, in RAM only, in the
        // test build.
        if (id.path.startsWith('.dart_tool/build/asset_graph.json')) continue;

        readerWriter.testing.writeBytes(id, await assetReader.readAsBytes(id));
      }
    }
  }

  // Use the default resolver if no experiments are enabled. This is much
  // faster.
  resolvers ??=
      packageConfig == null && enabledExperiments.isEmpty
          ? AnalyzerResolvers.sharedInstance
          : AnalyzerResolvers.custom(packageConfig: resolvedConfig);

  await testBuilder(
    resolveBuilder,
    inputs,
    readerWriter: readerWriter,
    resolvers: resolvers,
    packageConfig: packageConfig,
  );
  if (assetReaderChecks != null) {
    assetReaderChecks(readerWriter);
  }

  if (resolveBuilder.error == null) {
    return resolveBuilder.result as T;
  } else {
    Error.throwWithStackTrace(
      resolveBuilder.error!,
      resolveBuilder.stackTrace!,
    );
  }
}

/// A [Builder] that is only used to retrieve a [Resolver] instance.
///
/// It simulates what a user builder would do in order to resolve a primary
/// input given a set of dependencies to also use. See `resolveSource`.
class _ResolveSourceBuilder<T> implements Builder {
  final FutureOr<T> Function(Resolver) _action;
  final AssetId? _resolverFor;

  T? result;
  Object? error;
  StackTrace? stackTrace;

  _ResolveSourceBuilder(this._action, this._resolverFor);

  @override
  Future<void> build(BuildStep buildStep) async {
    if (_resolverFor != buildStep.inputId) return;
    try {
      result = await _action(buildStep.resolver);
    } catch (e, s) {
      error = e;
      stackTrace = s;
    }
  }

  @override
  final buildExtensions = const {
    '': ['.unused'],
  };
}
