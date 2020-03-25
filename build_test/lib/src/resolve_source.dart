// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:build/build.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:package_config/package_config.dart';
import 'package:pedantic/pedantic.dart';

import 'in_memory_reader.dart';
import 'in_memory_writer.dart';
import 'multi_asset_reader.dart';
import 'package_reader.dart';

final defaultResolvers = AnalyzerResolvers();

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
  AssetId inputId,
  PackageConfig packageConfig,
  Future<Null> tearDown,
  Resolvers resolvers,
}) {
  inputId ??= AssetId('_resolve_source', 'lib/_resolve_source.dart');
  return _resolveAssets(
    {
      '${inputId.package}|${inputId.path}': inputSource,
    },
    inputId.package,
    action,
    packageConfig: packageConfig,
    resolverFor: inputId,
    tearDown: tearDown,
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
/// By default the [Resolver] is unusable after [action] completes. To keep the
/// resolver active across multiple tests (for example, use `setUpAll` and
/// `tearDownAll`, provide a `tearDown` [Future]:
/// ```
/// import 'dart:async';
/// import 'package:build/build.dart';
/// import 'package:build_test/build_test.dart';
/// import 'package:test/test.dart';
///
/// void main() {
///   Resolver resolver;
///   var resolverDone = new Completer<Null>();
///
///   setUpAll(() async {
///     resolver = await resolveSources(
///       {...},
///       (resolver) => resolver,
///       tearDown: resolverDone.future,
///     );
///   });
///
///   tearDownAll(() => resolverDone.complete());
///
///   test('...', () async {
///     // Use the resolver here, and in other tests.
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
Future<T> resolveSources<T>(
  Map<String, String> inputs,
  FutureOr<T> Function(Resolver resolver) action, {
  PackageConfig packageConfig,
  String resolverFor,
  String rootPackage,
  Future<Null> tearDown,
  Resolvers resolvers,
}) {
  if (inputs == null || inputs.isEmpty) {
    throw ArgumentError.value(inputs, 'inputs', 'Must be a non-empty Map');
  }
  return _resolveAssets(
    inputs,
    rootPackage ?? AssetId.parse(inputs.keys.first).package,
    action,
    packageConfig: packageConfig,
    resolverFor: AssetId.parse(resolverFor ?? inputs.keys.first),
    tearDown: tearDown,
    resolvers: resolvers,
  );
}

/// A convenience for using [resolveSources] with a single [inputId] from disk.
Future<T> resolveAsset<T>(
  AssetId inputId,
  FutureOr<T> Function(Resolver resolver) action, {
  PackageConfig packageConfig,
  Future<Null> tearDown,
  Resolvers resolvers,
}) {
  return _resolveAssets(
    {
      '${inputId.package}|${inputId.path}': useAssetReader,
    },
    inputId.package,
    action,
    packageConfig: packageConfig,
    resolverFor: inputId,
    tearDown: tearDown,
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
  PackageConfig packageConfig,
  AssetId resolverFor,
  Future<Null> tearDown,
  Resolvers resolvers,
}) async {
  packageConfig ??= await loadPackageConfigUri(await Isolate.packageConfig);
  final assetReader = PackageAssetReader(packageConfig, rootPackage);
  final resolveBuilder = _ResolveSourceBuilder(
    action,
    resolverFor,
    tearDown,
  );
  final inputAssets = <AssetId, String>{};
  await Future.wait(inputs.keys.map((String rawAssetId) async {
    final assetId = AssetId.parse(rawAssetId);
    var assetValue = inputs[rawAssetId];
    if (assetValue == useAssetReader) {
      assetValue = await assetReader.readAsString(assetId);
    }
    inputAssets[assetId] = assetValue;
  }));
  final inMemory = InMemoryAssetReader(
    sourceAssets: inputAssets,
    rootPackage: rootPackage,
  );
  // We don't care about the results of this build, but we also can't await
  // it because that would block on the `tearDown` of the `resolveBuilder`.
  //
  // We also dont want to leak errors as unhandled async errors so we swallow
  // them here.
  //
  // Errors will still be reported through the resolver itself as well as the
  // `onDone` future that we return.
  unawaited(runBuilder(
    resolveBuilder,
    inputAssets.keys,
    MultiAssetReader([inMemory, assetReader]),
    InMemoryAssetWriter(),
    resolvers ?? defaultResolvers,
  ).catchError((_) {}));
  return resolveBuilder.onDone.future;
}

/// A [Builder] that is only used to retrieve a [Resolver] instance.
///
/// It simulates what a user builder would do in order to resolve a primary
/// input given a set of dependencies to also use. See `resolveSource`.
class _ResolveSourceBuilder<T> implements Builder {
  final FutureOr<T> Function(Resolver) _action;
  final Future _tearDown;
  final AssetId _resolverFor;

  final onDone = Completer<T>();

  _ResolveSourceBuilder(this._action, this._resolverFor, this._tearDown);

  @override
  Future<void> build(BuildStep buildStep) async {
    if (_resolverFor != buildStep.inputId) return;
    try {
      onDone.complete(await _action(buildStep.resolver));
    } catch (e, s) {
      onDone.completeError(e, s);
    }
    await _tearDown;
  }

  @override
  final buildExtensions = const {
    '': ['.unused']
  };
}
