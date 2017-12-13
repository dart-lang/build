// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_barback/build_barback.dart';
import 'package:package_resolver/package_resolver.dart';

import 'in_memory_reader.dart';
import 'in_memory_writer.dart';
import 'multi_asset_reader.dart';
import 'package_reader.dart';

/// Marker constant that may be used in combination with `resolveSources`.
///
/// Use of this string means instead of using the contents of the string as the
/// source of a given asset, instead read the file from the default or provided
/// [AssetReader].
///
/// TODO: Make public after resolveSources is added to the API.
const _useAssetReader = '__useAssetReader__';

/// Runs [action] using a created Resolver for [inputSource] and returns the
/// result.
///
/// Example use:
/// ```dart
/// var library = await resolveSource(r'''
///   library example;
///
///   import 'dart:collection';
///
///   abstract class Foo implements Map {}
/// ''', (resolver) => resolver.findLibraryByName('example'));
/// expect(library.getType('Foo'), isNotNull);
/// ```
///
/// By default the [Resolver] is unusable after the [action] completes so
/// references should not be kept after the future fires. To do more work in
/// multiple tests with a Resolver from the same source use the [tearDown]
/// argument:
///
/// ```dart
/// Completer<Null> resolverDone;
/// Resolver resolver;
///
/// setUpAll(() async {
///   resolverDone = new Completer<Null>();
///   resolver = await resolveSource('...', (resover) => resolver,
///       tearDown: resolverDone.future);
/// });
///
/// tearDown(() => resolverDone.complete());
///
/// test('...', () async {
///   // Use resolver.
/// });
/// ```
///
/// **NOTE**: All `package` dependencies are resolved using [PackageAssetReader]
/// - by default, [PackageAssetReader.currentIsolate]. A custom [resolver] may
/// be provided to map files not visible to the current package's runtime.
Future<T> resolveSource<T>(
  String inputSource,
  FutureOr<T> action(Resolver resolver), {
  AssetId inputId,
  PackageResolver resolver,
  Future<Null> tearDown,
}) {
  inputId ??= new AssetId('_resolve_source', 'lib/_resolve_source.dart');
  return _resolveAssets(
    {
      '${inputId.package}|${inputId.path}': inputSource,
    },
    inputId.package,
    action,
    resolver: resolver,
    tearDown: tearDown,
  );
}

/// Runs [action] using a created Resolver for [inputId] and returns the result.
///
/// Example use:
/// ```dart
/// var pkgBuildTest = new AssetId('build_test', 'lib/build_test.dart');
/// var library = await resolveSource(
///     pkgBuildTest, (resolver) => resolver.libraryFor(pkgBuildTest));
/// ```
///
/// By default the [Resolver] is unusable after the [action] completes so
/// references should not be kept after the future fires. To do more work in
/// multiple tests with a Resolver from the same source use the [tearDown]
/// argument:
///
/// ```dart
/// Completer<Null> resolverDone;
/// Resolver resolver;
///
/// setUpAll(() async {
///   resolverDone = new Completer<Null>();
///   resolver = await resolveAsset('...', (resolver) => resolver,
///       tearDown: resolverDone.future);
/// });
///
/// tearDown(() => resolverDone.complete());
///
/// test('...', () async {
///   // Use resolver.
/// });
/// ```
///
/// **NOTE**: All `package` dependencies are resolved using [PackageAssetReader]
/// - by default, [PackageAssetReader.currentIsolate]. A custom [resolver] may
/// be provided to map files not visible to the current package's runtime.
Future<T> resolveAsset<T>(
  AssetId inputId,
  FutureOr<T> action(Resolver resolver), {
  PackageResolver resolver,
  Future<Null> tearDown,
}) {
  return _resolveAssets(
    {
      '${inputId.package}|${inputId.path}': _useAssetReader,
    },
    inputId.package,
    action,
    resolver: resolver,
    tearDown: tearDown,
  );
}

/// Internal-only backing implementation of `resolve{Asset|Source(s)}`.
///
/// If the value of an entry of [inputs] is [_useAssetReader] then the value is
/// instead read from the file system, otherwise the provided text is used as
/// the contents of the asset.
Future<T> _resolveAssets<T>(
  Map<String, String> inputs,
  String rootPackage,
  FutureOr<T> action(Resolver resolver), {
  PackageResolver resolver,
  Future<Null> tearDown,
}) async {
  final syncResolver = await (resolver ?? PackageResolver.current).asSync;
  final assetReader = new PackageAssetReader(syncResolver, rootPackage);
  final resolveBuilder = new _ResolveSourceBuilder(action, tearDown);
  final inputAssets = <AssetId, String>{};
  await Future.wait(inputs.keys.map((String rawAssetId) async {
    final assetId = new AssetId.parse(rawAssetId);
    var assetValue = inputs[rawAssetId];
    if (assetValue == _useAssetReader) {
      assetValue = await assetReader.readAsString(assetId);
    }
    inputAssets[assetId] = assetValue;
  }));
  final inMemory = new InMemoryAssetReader(
    sourceAssets: inputAssets,
    rootPackage: rootPackage,
  );
  // We don't care about the results of this build.
  // ignore: unawaited_futures
  runBuilder(
    resolveBuilder,
    inputAssets.keys,
    new MultiAssetReader([inMemory, assetReader]),
    new InMemoryAssetWriter(),
    const BarbackResolvers(),
  );
  return resolveBuilder.onDone.future;
}

typedef FutureOr<T> _ResolverAction<T>(Resolver resolver);

/// A [Builder] that is only used to retrieve a [Resolver] instance.
///
/// It simulates what a user builder would do in order to resolve a primary
/// input given a set of dependencies to also use. See `resolveSource`.
class _ResolveSourceBuilder<T> implements Builder {
  final _ResolverAction<T> _action;
  final Future _tearDown;
  final onDone = new Completer<T>();

  _ResolveSourceBuilder(this._action, this._tearDown);

  @override
  Future<Null> build(BuildStep buildStep) async {
    var result = await _action(buildStep.resolver);
    onDone.complete(result);
    await _tearDown;
  }

  @override
  final buildExtensions = const {
    '': const ['.unused']
  };
}
