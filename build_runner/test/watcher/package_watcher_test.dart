// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_runner/build_runner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

void main() {
  group('Should emit events', () {
    final graph = new PackageGraph.fromRoot(
      new PackageNode('test_lib', null, null, Uri.parse('test_lib/')),
    );
    
    PackageWatcher package;
    Watcher watcher;
    
    setUp(() {
      package = new PackageWatcher(graph, watch: (_) => watcher);
    });
    
    test('when an asset is added', () async {
      watcher = new FakeWatcher('test_lib', new Stream.fromIterable([
        new WatchEvent(ChangeType.ADD, p.join('lib', 'test_lib.dart')),
      ]));
      expect(package.watch('lib'), emitsInOrder([
        new AssetChange(
          new AssetId('test_lib', p.join('lib', 'test_lib.dart')),
          ChangeType.ADD,
        ),
      ]));
    });

    test('when an asset is changed', () async {
      watcher = new FakeWatcher('test_lib', new Stream.fromIterable([
        new WatchEvent(ChangeType.MODIFY, p.join('lib', 'test_lib.dart')),
      ]));
      expect(package.watch('lib'), emitsInOrder([
        new AssetChange(
          new AssetId('test_lib', p.join('lib', 'test_lib.dart')),
          ChangeType.MODIFY,
        ),
      ]));
    });

    test('when an asset is removed', () async {
      watcher = new FakeWatcher('test_lib', new Stream.fromIterable([
        new WatchEvent(ChangeType.REMOVE, p.join('lib', 'test_lib.dart')),
      ]));
      expect(package.watch('lib'), emitsInOrder([
        new AssetChange(
          new AssetId('test_lib', p.join('lib', 'test_lib.dart')),
          ChangeType.REMOVE,
        ),
      ]));
    });
  });
}

// A fake watcher implementation that emits user-determined events.
class FakeWatcher implements Watcher {
  @override
  final Stream<WatchEvent> events;

  @override
  final String path;

  FakeWatcher(this.path, this.events);

  @override
  bool get isReady => true;

  @override
  Future get ready => new Future.value();
}
