// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
// ignore: implementation_imports
import 'package:build/src/internal.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_test/build_test.dart';
// ignore: implementation_imports
import 'package:build_test/src/in_memory_reader_writer.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

// TODO(davidmorgan): refactor to remove this class.
class InMemoryRunnerAssetReaderWriter extends InMemoryAssetReaderWriter
    implements AssetReader, RunnerAssetWriter {
  final _onCanReadController = StreamController<AssetId>.broadcast();
  Stream<AssetId> get onCanRead => _onCanReadController.stream;
  void Function(AssetId)? onDelete;

  factory InMemoryRunnerAssetReaderWriter({String? rootPackage}) {
    final filesystem = InMemoryFilesystem();
    return InMemoryRunnerAssetReaderWriter.using(
      assetsRead: {},
      rootPackage: rootPackage ?? 'unset',
      assetFinder: InMemoryAssetFinder(filesystem, rootPackage),
      assetPathProvider: const InMemoryAssetPathProvider(),
      filesystem: filesystem,
      cache: const PassthroughFilesystemCache(),
      inputTracker: InputTracker(),
    );
  }

  InMemoryRunnerAssetReaderWriter.using({
    required super.assetsRead,
    required super.rootPackage,
    required super.assetFinder,
    required super.assetPathProvider,
    required super.filesystem,
    required super.cache,
    required super.inputTracker,
  }) : super.using();

  @override
  InMemoryRunnerAssetReaderWriter copyWith({
    AssetPathProvider? assetPathProvider,
    FilesystemCache? cache,
    InputTracker? inputTracker,
  }) => InMemoryRunnerAssetReaderWriter.using(
    assetsRead: assetsRead,
    rootPackage: rootPackage,
    assetFinder: assetFinder,
    assetPathProvider: assetPathProvider ?? this.assetPathProvider,
    filesystem: filesystem,
    cache: cache ?? this.cache,
    inputTracker: inputTracker ?? this.inputTracker,
  );

  @override
  Future<bool> canRead(AssetId id) {
    _onCanReadController.add(id);
    return super.canRead(id);
  }

  @override
  Future writeAsBytes(AssetId id, List<int> bytes) async {
    var type = testing.exists(id) ? ChangeType.MODIFY : ChangeType.ADD;
    await super.writeAsBytes(id, bytes);
    FakeWatcher.notifyWatchers(
      WatchEvent(type, p.absolute(id.package, p.fromUri(id.path))),
    );
  }

  @override
  Future writeAsString(
    AssetId id,
    String contents, {
    Encoding encoding = utf8,
  }) async {
    var type = testing.exists(id) ? ChangeType.MODIFY : ChangeType.ADD;
    await super.writeAsString(id, contents, encoding: encoding);
    FakeWatcher.notifyWatchers(
      WatchEvent(type, p.absolute(id.package, p.fromUri(id.path))),
    );
  }

  @override
  Future delete(AssetId id) async {
    onDelete?.call(id);
    testing.delete(id);
    FakeWatcher.notifyWatchers(
      WatchEvent(ChangeType.REMOVE, p.absolute(id.package, p.fromUri(id.path))),
    );
  }

  @override
  Future<void> completeBuild() async {}
}
