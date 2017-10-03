// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:build/build.dart';
import 'package:build_runner/src/package_graph/package_graph.dart';
import 'package:build_runner/src/watcher/asset_change.dart';
import 'package:build_runner/src/watcher/node_watcher.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

void main() {
  group('PackageNodeWatcher', () {
    PackageNodeWatcher nodeWatcher;
    FakeWatcher watcher;

    test('should emit a changed asset', () {
      nodeWatcher = new PackageNodeWatcher(
        new PackageNode.noPubspec('a', path: '/b/a'),
        watch: (path) => watcher = new FakeWatcher(path),
      );

      expect(
        nodeWatcher.watch('lib'),
        emitsInOrder([
          new AssetChange(
            new AssetId('a', 'lib/1.dart'),
            ChangeType.ADD,
          ),
          new AssetChange(
            new AssetId('a', 'lib/2.dart'),
            ChangeType.MODIFY,
          ),
          new AssetChange(
            new AssetId('a', 'lib/3.dart'),
            ChangeType.REMOVE,
          ),
        ]),
      );

      watcher
        ..emitAdd(p.join('/b', 'a', 'lib', '1.dart'))
        ..emitModify(p.join('/b', 'a', 'lib', '2.dart'))
        ..emitRemove(p.join('/b', 'a', 'lib', '3.dart'));
    });

    test('should also respect relative watch URLs', () {
      nodeWatcher = new PackageNodeWatcher(
        new PackageNode.noPubspec(
          'a',
          path: '/b/a',
        ),
        watch: (path) => watcher = new FakeWatcher(path),
      );

      expect(
        nodeWatcher.watch('lib'),
        emitsInOrder([
          new AssetChange(
            new AssetId('a', 'lib/1.dart'),
            ChangeType.ADD,
          ),
          new AssetChange(
            new AssetId('a', 'lib/2.dart'),
            ChangeType.MODIFY,
          ),
          new AssetChange(
            new AssetId('a', 'lib/3.dart'),
            ChangeType.REMOVE,
          ),
        ]),
      );

      var relative = p.relative('/b/a', from: p.current);

      watcher
        ..emitAdd(p.join(relative, 'lib', '1.dart'))
        ..emitModify(p.join(relative, 'lib', '2.dart'))
        ..emitRemove(p.join(relative, 'lib', '3.dart'));
    });
  });
}

class FakeWatcher implements Watcher {
  final _events = new StreamController<WatchEvent>();

  @override
  final String path;

  FakeWatcher(this.path);

  /// Emits a [ChangeType.ADD] event for [path].
  void emitAdd(String path) {
    _events.add(new WatchEvent(ChangeType.ADD, path));
  }

  /// Emits a [ChangeType.MODIFY] event for [path].
  void emitModify(String path) {
    _events.add(new WatchEvent(ChangeType.MODIFY, path));
  }

  /// Emits a [ChangeType.REMOVE] event for [path].
  void emitRemove(String path) {
    _events.add(new WatchEvent(ChangeType.REMOVE, path));
  }

  @override
  Stream<WatchEvent> get events => _events.stream;

  @override
  final isReady = true;

  @override
  Future<Null> get ready => new Future.value();
}
