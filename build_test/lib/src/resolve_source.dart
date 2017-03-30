// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_barback/build_barback.dart';
import 'package:glob/glob.dart';

import 'in_memory_reader.dart';
import 'in_memory_writer.dart';
import 'multi_asset_reader.dart';
import 'package:package_resolver/package_resolver.dart';
import 'package_reader.dart';

/// Returns a future that completes with a source [Resolver] for [inputSource].
///
/// Example use:
/// ```dart
/// await resolveSource(r'''
///   import 'dart:collection';
///
///   external Map createMap();
/// ''', rootPackage: 'some_pkg')
/// ```
///
/// **NOTE**: All `package` dependencies are resolved using [PackageAssetReader]
/// - by default, [PackageAssetReader.currentIsolate]. A custom [reader] may be
/// provided to access files not visible to the current package's runtime.
Future<Resolver> resolveSource(
  String inputSource, {
  AssetId inputId,
  PackageResolver resolver,
}) async {
  // If not provided use a fake asset and package.
  inputId ??= new AssetId('_resolve_source', '_resolve_source.dart');
  resolver ??= PackageResolver.current;
  var syncResolver = await resolver.asSync;
  var reader = new PackageAssetReader(syncResolver, inputId.package);
  var completer = new Completer<Resolver>();
  var builder = new _ResolveSourceBuilder(completer);
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
    new MultiAssetReader([
      inMemory,
      reader,
    ]),
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

  const _ResolveSourceBuilder(this._resolver);

  @override
  Future<Null> build(BuildStep buildStep) {
    return new Future.sync(() {
      if (!_resolver.isCompleted) {
        _resolver.complete(buildStep.resolver);
      }
    });
  }

  @override
  List<AssetId> declareOutputs(AssetId inputId) => const [];
}
