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

/// Marker constant that may be used in combination with [resolveSources].
///
/// Use of this string means instead of using the contents of the string as the
/// source of a given asset, instead read the file from the default or provided
/// [AssetReader].
const useAssetReader = '__useAssetReader__';

/// A convenience method for using [resolveSources] with a single source file.
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
/// **NOTE**: All `package` dependencies are resolved using [PackageAssetReader]
/// - by default, [PackageAssetReader.currentIsolate]. A custom [resolver] may
/// be provided to map files not visible to the current package's runtime.
Future<T> resolveSources<T>(
  Map<String, String> inputs,
  FutureOr<T> action(Resolver resolver), {
  PackageResolver resolver,
  String rootPackage,
  Future<Null> tearDown,
}) {
  if (inputs == null || inputs.isEmpty) {
    throw new ArgumentError.value(inputs, 'inputs', 'Must be a non-empty Map');
  }
  return _resolveAssets(
    inputs,
    rootPackage ?? new AssetId.parse(inputs.keys.first).package,
    action,
    resolver: resolver,
    tearDown: tearDown,
  );
}

/// A convenience for using [resolveSources] with a single [inputId] from disk.
Future<T> resolveAsset<T>(
  AssetId inputId,
  FutureOr<T> action(Resolver resolver), {
  PackageResolver resolver,
  Future<Null> tearDown,
}) {
  return _resolveAssets(
    {
      '${inputId.package}|${inputId.path}': useAssetReader,
    },
    inputId.package,
    action,
    resolver: resolver,
    tearDown: tearDown,
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
    if (assetValue == useAssetReader) {
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
    if (onDone.isCompleted) return;
    var result = await _action(buildStep.resolver);
    if (!onDone.isCompleted) {
      // With resolveSources (plural), this function is called multiple times
      // but we only care about it once to get a handle to "Resolver".
      onDone.complete(result);
    }
    await _tearDown;
  }

  @override
  final buildExtensions = const {
    '': const ['.unused']
  };
}
