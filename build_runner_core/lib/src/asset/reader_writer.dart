// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as path;

import '../package_graph/package_graph.dart';
import '../util/constants.dart';
import 'writer.dart';

/// Pluggable [AssetReader] and [AssetWriter].
class ReaderWriter extends AssetReader
    implements AssetReaderState, RunnerAssetWriter, AssetReaderWriter {
  /// The package the generator is running for.
  ///
  /// Deletes are only allowed within this package.
  final String rootPackage;

  @override
  final AssetFinder assetFinder;
  @override
  final AssetPathProvider assetPathProvider;
  @override
  final GeneratedAssetHider generatedAssetHider;
  @override
  final Filesystem filesystem;
  @override
  final FilesystemCache cache;
  final FilesystemDigests digests;

  final void Function(AssetId)? onDelete;

  /// A [ReaderWriter] suitable for real builds.
  ///
  /// [packageGraph] is used for mapping paths and finding assets. The
  /// `dart-io` filesystem is used with no cache.
  ///
  /// Use [copyWith] to change settings such as caching.
  factory ReaderWriter(PackageGraph packageGraph) => ReaderWriter.using(
    rootPackage: packageGraph.root.name,
    assetFinder: PackageGraphAssetFinder(packageGraph),
    assetPathProvider: packageGraph,
    generatedAssetHider: const NoopGeneratedAssetHider(),
    filesystem: IoFilesystem(),
    cache: const PassthroughFilesystemCache(),
    digests: const NoopFilesystemDigests(),
    onDelete: null,
  );

  ReaderWriter.using({
    required this.rootPackage,
    required this.assetFinder,
    required this.assetPathProvider,
    required this.generatedAssetHider,
    required this.filesystem,
    required this.cache,
    required this.digests,
    required this.onDelete,
  });

  @override
  ReaderWriter copyWith({
    FilesystemCache? cache,
    FilesystemDigests? digests,
    GeneratedAssetHider? generatedAssetHider,
    void Function(AssetId)? onDelete,
  }) => ReaderWriter.using(
    rootPackage: rootPackage,
    assetFinder: assetFinder,
    assetPathProvider: assetPathProvider,
    generatedAssetHider: generatedAssetHider ?? this.generatedAssetHider,
    filesystem: filesystem,
    cache: cache ?? this.cache,
    digests: digests ?? this.digests,
    onDelete: onDelete ?? this.onDelete,
  );

  String _pathFor(AssetId id) =>
      assetPathProvider.pathFor(generatedAssetHider.maybeHide(id, rootPackage));

  @override
  Future<bool> canRead(AssetId id) async {
    final result = await cache.exists(
      id,
      ifAbsent: () async {
        final path = _pathFor(id);
        return filesystem.exists(path);
      },
    );
    digests.addOrCheck(id, result ? await digest(id) : Digest(const []));
    return result;
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    final result = await cache.readAsBytes(
      id,
      ifAbsent: () async {
        final path = _pathFor(id);
        if (!await filesystem.exists(path)) {
          throw AssetNotFoundException(id, path: path);
        }
        return filesystem.readAsBytes(path);
      },
    );
    digests.addOrCheck(id, _digest(id, result));
    return result;
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    final result = await cache.readAsString(
      id,
      encoding: encoding,
      ifAbsent: () async {
        final path = _pathFor(id);
        if (!await filesystem.exists(path)) {
          throw AssetNotFoundException(id, path: path);
        }
        return filesystem.readAsBytes(path);
      },
    );
    digests.addOrCheck(id, await digest(id));
    return result;
  }

  Digest _digest(AssetId id, List<int> bytes) =>
      md5.convert(bytes + id.toString().codeUnits);

  // This is only for generators, so only `BuildStep` needs to implement it.
  @override
  Stream<AssetId> findAssets(Glob glob) => throw UnimplementedError();

  // [AssetWriter] methods.

  @override
  Future<void> writeAsBytes(AssetId id, List<int> bytes) async {
    final path = _pathFor(id);
    await filesystem.writeAsBytes(path, bytes);
  }

  @override
  Future<void> writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
  }) async {
    final path = _pathFor(id);
    await filesystem.writeAsString(path, contents, encoding: encoding);
  }

  @override
  Future<void> delete(AssetId id) async {
    onDelete?.call(id);
    final path = _pathFor(id);
    // Hidden generated files are moved by `assetPathProvider` under the root
    // package folder, and it's allowed to delete them. So for assets in a
    // different package, check if the path has mapped onto the generated output
    // path, and if so allow the deleted.
    var generatedOutputPath = assetPathProvider.pathFor(
      AssetId(rootPackage, generatedOutputDirectory),
    );
    if (id.package != rootPackage && !path.startsWith(generatedOutputPath)) {
      throw InvalidOutputException(
        id,
        'Should not delete assets outside of $rootPackage',
      );
    }
    await filesystem.delete(path);
  }

  @override
  Future<void> completeBuild() async {
    // TODO(davidmorgan): add back write caching, "batching".
  }
}

/// [AssetFinder] that uses [PackageGraph] to map packages to paths, then
/// uses the `dart:io` filesystem to find files.
///
/// TODO(davidmorgan): read via `Filesystem` instead of `dart-io`.
class PackageGraphAssetFinder implements AssetFinder {
  final PackageGraph packageGraph;

  PackageGraphAssetFinder(this.packageGraph);

  @override
  Stream<AssetId> find(Glob glob, {String? package}) {
    var packageNode =
        package == null ? packageGraph.root : packageGraph[package];
    if (packageNode == null) {
      throw ArgumentError(
        "Could not find package '$package' which was listed as "
        'an input. Please ensure you have that package in your deps, or '
        'remove it from your input sets.',
      );
    }
    return glob
        .list(followLinks: true, root: packageNode.path)
        .where((e) => e is File && !path.basename(e.path).startsWith('._'))
        .cast<File>()
        .map((file) => _fileToAssetId(file, packageNode));
  }

  /// Creates an [AssetId] for [file], which is a part of [packageNode].
  static AssetId _fileToAssetId(File file, PackageNode packageNode) {
    var filePath = path.normalize(file.absolute.path);
    var relativePath = path.relative(filePath, from: packageNode.path);
    return AssetId(packageNode.name, relativePath);
  }
}
