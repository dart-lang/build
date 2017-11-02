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
        String inputSource, FutureOr<T> action(Resolver resolver),
        {AssetId inputId, PackageResolver resolver, Future tearDown}) =>
    _resolveAsset(
        inputId ?? new AssetId('_resolver_source', 'lib/_resolve_source.dart'),
        action,
        inputContents: inputSource,
        resolver: resolver,
        tearDown: tearDown);

/// Runs [action] using a created Resolver for [input] and returns the result.
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
///   resolver = await resolveAsset('...', (resover) => resolver,
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
Future<T> resolveAsset<T>(AssetId input, FutureOr<T> action(Resolver resolver),
        {PackageResolver resolver, Future tearDown}) =>
    _resolveAsset(input, action, resolver: resolver, tearDown: tearDown);

/// Internal only backing implementation of `resolveAsset` and `resolveSource`.
///
/// If [inputContents] is non-null, it is used instead of reading [input] from
/// the file system.
Future<T> _resolveAsset<T>(AssetId input, FutureOr<T> action(Resolver resolver),
    {String inputContents, PackageResolver resolver, Future tearDown}) async {
  resolver ??= PackageResolver.current;
  var syncResolver = await resolver.asSync;
  var reader = new PackageAssetReader(syncResolver, input.package);
  var builder = new _ResolveSourceBuilder(action, tearDown);
  var inputs = [input];
  var inMemory = new InMemoryAssetReader(
    sourceAssets: {
      input: inputContents ?? await reader.readAsString(input),
    },
    rootPackage: input.package,
  );
  // We don't care about the results of this build.
  // ignore: unawaited_futures
  runBuilder(builder, inputs, new MultiAssetReader([inMemory, reader]),
      new InMemoryAssetWriter(), const BarbackResolvers());
  return builder.onDone.future;
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
