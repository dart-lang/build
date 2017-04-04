// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_barback/build_barback.dart';

import 'in_memory_reader.dart';
import 'in_memory_writer.dart';
import 'multi_asset_reader.dart';
import 'package:package_resolver/package_resolver.dart';
import 'package_reader.dart';

/// Returns a future that completes with a source [Resolver] for [inputSource].
///
/// Example use:
/// ```dart
/// var resolver = await resolveSource(r'''
///   library example;
///
///   import 'dart:collection';
///
///   abstract class Foo implements Map {}
/// ''');
/// var element = resolver.getLibraryByName('example');
/// expect(element.getType('Foo'), isNotNull);
/// ```
///
/// By default, the returned [Resolver] is destroyed after the event loop is
/// completed. In order to control the lifecycle, pass a [Completer] and
/// complete it turning the `tearDown` phase of testing:
/// ```dart
/// Completer<Null> onTearDown;
///
/// setUp(() {
///   onTearDown = new Completer<Null>();
/// });
///
/// tearDown(() => onTearDown.complete());
///
/// test('...', () async {
///   var resolver = await resolveSource('...', tearDown: onTearDown.future);
///   // Use resolver.
/// });
/// ```
///
/// **NOTE**: All `package` dependencies are resolved using [PackageAssetReader]
/// - by default, [PackageAssetReader.currentIsolate]. A custom [resolver] may
/// be provided to map files not visible to the current package's runtime.
Future<Resolver> resolveSource(String inputSource,
    {AssetId inputId, PackageResolver resolver, Future<Null> tearDown}) async {
  // If not provided use a fake asset and package.
  inputId ??= new AssetId('_resolve_source', '_resolve_source.dart');
  resolver ??= PackageResolver.current;
  tearDown ??= new Future.delayed(Duration.ZERO);
  var syncResolver = await resolver.asSync;
  var reader = new PackageAssetReader(syncResolver, inputId.package);
  var completer = new Completer<Resolver>();
  var builder = new _ResolveSourceBuilder(completer, tearDown);
  var inputs = [inputId];
  var inMemory = new InMemoryAssetReader(
    sourceAssets: {
      inputId: new DatedString(inputSource),
    },
    rootPackage: inputId.package,
  );
  // We don't care about the results of this build.
  // ignore: unawaited_futures
  runBuilder(
    builder,
    inputs,
    new MultiAssetReader([inMemory, reader]),
    new InMemoryAssetWriter(),
    const BarbackResolvers(),
    rootPackage: inputId.package,
  );
  return completer.future;
}

/// A [Builder] that is only used to retrieve a [Resolver] instance.
///
/// It simulates what a user builder would do in order to resolve a primary
/// input given a set of dependencies to also use. See `resolveSource`.
class _ResolveSourceBuilder implements Builder {
  final Completer<Resolver> _resolver;
  final Future<Null> _tearDown;

  const _ResolveSourceBuilder(this._resolver, this._tearDown);

  @override
  Future<Null> build(BuildStep buildStep) async {
    await new Future.sync(() {
      if (!_resolver.isCompleted) {
        _resolver.complete(buildStep.resolver);
      }
    });
    await _tearDown;
  }

  @override
  List<AssetId> declareOutputs(AssetId inputId) => const [];
}
