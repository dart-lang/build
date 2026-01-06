// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as path;

import '../build_plan/package_graph.dart';
import '../constants.dart';
import '../logging/timed_activities.dart';
import 'asset_finder.dart';
import 'asset_path_provider.dart';
import 'filesystem.dart';
import 'filesystem_cache.dart';
import 'generated_asset_hider.dart';

/// File operations during a build.
///
/// [AssetReader] and [AssetWriter] are the builder-facing file operations APIs,
/// and are implemented here so that `TestReaderWriter` can offer them.
class ReaderWriter implements AssetReader, AssetWriter {
  /// The package the generator is running for.
  ///
  /// Deletes are only allowed within this package.
  final String rootPackage;

  final AssetFinder assetFinder;
  final AssetPathProvider assetPathProvider;
  final GeneratedAssetHider generatedAssetHider;
  final Filesystem filesystem;
  final FilesystemCache cache;

  final void Function(AssetId)? onDelete;

  /// A [ReaderWriter] suitable for real builds.
  ///
  /// [packageGraph] is used for mapping paths and finding assets. The
  /// `dart-io` filesystem is used with no cache.
  ///
  /// Use [copyWith] to change settings such as caching.
  factory ReaderWriter(PackageGraph packageGraph) => ReaderWriter.using(
    // TODO
    rootPackage: packageGraph.currentPackage.name,
    assetFinder: PackageGraphAssetFinder(packageGraph),
    assetPathProvider: packageGraph,
    generatedAssetHider: const NoopGeneratedAssetHider(),
    filesystem: IoFilesystem(),
    cache: const PassthroughFilesystemCache(),
    onDelete: null,
  );

  ReaderWriter.using({
    required this.rootPackage,
    required this.assetFinder,
    required this.assetPathProvider,
    required this.generatedAssetHider,
    required this.filesystem,
    required this.cache,
    required this.onDelete,
  });

  ReaderWriter copyWith({
    FilesystemCache? cache,
    GeneratedAssetHider? generatedAssetHider,
    void Function(AssetId)? onDelete,
  }) => ReaderWriter.using(
    rootPackage: rootPackage,
    assetFinder: assetFinder,
    assetPathProvider: assetPathProvider,
    generatedAssetHider: generatedAssetHider ?? this.generatedAssetHider,
    filesystem: filesystem,
    cache: cache ?? this.cache,
    onDelete: onDelete ?? this.onDelete,
  );

  String _pathFor(AssetId id) =>
      assetPathProvider.pathFor(generatedAssetHider.maybeHide(id, rootPackage));

  @override
  Future<bool> canRead(AssetId id) {
    return Future.value(
      TimedActivity.read.run(
        () => cache.exists(
          id,
          ifAbsent: () {
            final path = _pathFor(id);
            return filesystem.existsSync(path);
          },
        ),
      ),
    );
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) {
    return Future.value(
      TimedActivity.read.run(
        () => cache.readAsBytes(
          id,
          ifAbsent: () {
            final path = _pathFor(id);
            if (!filesystem.existsSync(path)) {
              throw AssetNotFoundException(id, path: path);
            }
            return filesystem.readAsBytesSync(path);
          },
        ),
      ),
    );
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) {
    return Future.value(
      TimedActivity.read.run(
        () => cache.readAsString(
          id,
          encoding: encoding,
          ifAbsent: () {
            final path = _pathFor(id);
            if (!filesystem.existsSync(path)) {
              throw AssetNotFoundException(id, path: path);
            }
            return filesystem.readAsBytesSync(path);
          },
        ),
      ),
    );
  }

  // [AssetWriter] methods.

  @override
  Future<void> writeAsBytes(AssetId id, List<int> bytes) {
    TimedActivity.write.run(() {
      final path = _pathFor(id);
      cache.writeAsBytes(
        id,
        bytes,
        writer: () {
          filesystem.writeAsBytesSync(path, bytes);
        },
      );
    });
    return Future.value();
  }

  @override
  Future<void> writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
  }) {
    TimedActivity.write.run(() {
      final path = _pathFor(id);
      cache.writeAsString(
        id,
        contents,
        writer: () {
          filesystem.writeAsStringSync(path, contents, encoding: encoding);
        },
      );
    });
    return Future.value();
  }

  @override
  Future<Digest> digest(AssetId id) async {
    final digestSink = AccumulatorSink<Digest>();
    md5.startChunkedConversion(digestSink)
      ..add(await readAsBytes(id))
      ..add(id.toString().codeUnits)
      ..close();
    return digestSink.events.first;
  }

  Future<void> delete(AssetId id) {
    TimedActivity.write.run(() {
      onDelete?.call(id);
      final path = _pathFor(id);
      // Hidden generated files are moved by `assetPathProvider` under the root
      // package folder, and it's allowed to delete them. So for assets in a
      // different package, check if the path has mapped onto the generated
      // output path, and if so allow the deleted.
      final generatedOutputPath = assetPathProvider.pathFor(
        AssetId(rootPackage, generatedOutputDirectory),
      );
      if (id.package != rootPackage && !path.startsWith(generatedOutputPath)) {
        throw InvalidOutputException(
          id,
          'Should not delete assets outside of $rootPackage',
        );
      }
      cache.delete(
        id,
        deleter: () {
          filesystem.deleteSync(path);
        },
      );
    });
    return Future.value();
  }

  Future<void> deleteDirectory(AssetId id) {
    TimedActivity.write.run(() {
      final path = _pathFor(id);
      filesystem.deleteDirectorySync(path);
    });
    return Future.value();
  }

  // This is only for builders, so only `BuildStep` needs to implement it.
  @override
  Stream<AssetId> findAssets(Glob glob) => throw UnimplementedError();
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
    final packageNode =
        // TODO
        package == null ? packageGraph.currentPackage : packageGraph[package];
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
    final filePath = path.normalize(file.absolute.path);
    final relativePath = path.relative(filePath, from: packageNode.path);
    return AssetId(packageNode.name, relativePath);
  }
}
