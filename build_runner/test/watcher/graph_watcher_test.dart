// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import 'package:build_runner_core/src/package_graph/package_graph.dart';
import 'package:build_runner/src/watcher/asset_change.dart';
import 'package:build_runner/src/watcher/graph_watcher.dart';
import 'package:build_runner/src/watcher/node_watcher.dart';

import 'package:_test_common/package_graphs.dart';

void main() {
  group('PackageGraphWatcher', () {
    test('should aggregate changes from all nodes', () {
      final graph = buildPackageGraph({
        rootPackage('a', path: '/g/a'): ['b'],
        package('b', path: '/g/b'): []
      });
      final nodes = {
        'a': FakeNodeWatcher(graph['a']),
        'b': FakeNodeWatcher(graph['b']),
        r'$sdk': FakeNodeWatcher(null),
      };
      final watcher = PackageGraphWatcher(graph, watch: (node) {
        return nodes[node.name];
      });

      nodes['a'].emitAdd('lib/a.dart');
      nodes['b'].emitAdd('lib/b.dart');

      expect(
          watcher.watch(),
          emitsInOrder([
            AssetChange(AssetId('a', 'lib/a.dart'), ChangeType.ADD),
            AssetChange(AssetId('b', 'lib/b.dart'), ChangeType.ADD),
          ]));
    });

    test('should avoid duplicate changes with nested packages', () {
      final graph = buildPackageGraph({
        rootPackage('a', path: '/g/a'): ['b'],
        package('b', path: '/g/a/b'): []
      });
      final nodes = {
        'a': FakeNodeWatcher(graph['a']),
        'b': FakeNodeWatcher(graph['b']),
        r'$sdk': FakeNodeWatcher(null),
      };
      final watcher = PackageGraphWatcher(graph, watch: (node) {
        return nodes[node.name];
      });

      nodes['a'].emitAdd('lib/a.dart');
      nodes['b'].emitAdd('lib/b.dart');

      expect(
          watcher.watch(),
          emitsInOrder([
            AssetChange(AssetId('a', 'lib/a.dart'), ChangeType.ADD),
            AssetChange(AssetId('b', 'lib/b.dart'), ChangeType.ADD),
          ]));
    });

    test('should avoid watchers on pub dependencies', () {
      final graph = buildPackageGraph({
        rootPackage('a', path: '/g/a'): ['b'],
        package('b', path: '/g/a/b/', type: DependencyType.hosted): []
      });
      final nodes = {
        'a': FakeNodeWatcher(graph['a']),
        r'$sdk': FakeNodeWatcher(null),
      };
      noBWatcher(PackageNode node) {
        if (node.name == 'b') throw 'No watcher for B!';
        return nodes[node.name];
      }

      final watcher = PackageGraphWatcher(graph, watch: noBWatcher);

      // ignore: unawaited_futures
      watcher.watch().drain();

      for (final node in nodes.values) {
        node.markReady();
      }

      expect(watcher.ready, completes);
    });

    test('ready waits for all node watchers to be ready', () async {
      final graph = buildPackageGraph({
        rootPackage('a', path: '/g/a'): ['b'],
        package('b', path: '/g/b'): []
      });
      final nodes = {
        'a': FakeNodeWatcher(graph['a']),
        'b': FakeNodeWatcher(graph['b']),
        r'$sdk': FakeNodeWatcher(null),
      };
      final watcher = PackageGraphWatcher(graph, watch: (node) {
        return nodes[node.name];
      });
      // We have to listen in order for `ready` to complete.
      // ignore: unawaited_futures
      watcher.watch().drain();

      var done = false;
      // ignore: unawaited_futures
      watcher.ready.then((_) => done = true);
      await Future.value();

      for (final node in nodes.values) {
        expect(done, isFalse);
        node.markReady();
        await Future.value();
      }

      await Future.value();
      expect(done, isTrue);
    });
  });
}

class FakeNodeWatcher implements PackageNodeWatcher {
  final PackageNode _package;
  final _events = StreamController<AssetChange>();

  FakeNodeWatcher(this._package);

  @override
  Watcher get watcher => _watcher;
  final _watcher = _FakeWatcher();

  void markReady() => _watcher._readyCompleter.complete();

  void emitAdd(String path) {
    _events.add(
      AssetChange(
        AssetId(_package.name, path),
        ChangeType.ADD,
      ),
    );
  }

  @override
  Stream<AssetChange> watch([_]) => _events.stream;
}

class _FakeWatcher implements Watcher {
  @override
  Stream<WatchEvent> get events => throw UnimplementedError();

  @override
  bool get isReady => _readyCompleter.isCompleted;

  @override
  String get path => throw UnimplementedError();

  @override
  Future get ready => _readyCompleter.future;
  final _readyCompleter = Completer();
}
