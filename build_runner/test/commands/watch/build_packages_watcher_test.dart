// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:build/build.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/commands/watch/asset_change.dart';
import 'package:build_runner/src/commands/watch/build_package_watcher.dart';
import 'package:build_runner/src/commands/watch/build_packages_watcher.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

void main() {
  group('BuildPackagesWatcher', () {
    final buildPackages = BuildPackages.singlePackageBuild('a', {
      BuildPackage(
        name: 'a',
        path: '/g/a',
        isOutput: true,
        watch: true,
        dependencies: ['b'],
      ),
      BuildPackage(name: 'b', path: '/g/b', watch: true),
    });
    test('should aggregate changes from all nodes', () {
      final nodes = {
        'a': FakeNodeWatcher(buildPackages['a']!),
        'b': FakeNodeWatcher(buildPackages['b']!),
        r'$sdk': FakeNodeWatcher(
          BuildPackage(name: '\$sdk', path: '', watch: true),
        ),
      };
      final watcher = BuildPackagesWatcher(
        buildPackages,
        watch: (node) {
          return nodes[node.name]!;
        },
      );

      nodes['a']!.emitAdd('lib/a.dart');
      nodes['b']!.emitAdd('lib/b.dart');

      expect(
        watcher.watch(),
        emitsInOrder([
          AssetChange(AssetId('a', 'lib/a.dart'), ChangeType.ADD),
          AssetChange(AssetId('b', 'lib/b.dart'), ChangeType.ADD),
        ]),
      );
    });

    test('should avoid duplicate changes with nested packages', () async {
      final buildPackages = BuildPackages.singlePackageBuild('a', {
        BuildPackage(
          name: 'a',
          path: '/g/a',
          isOutput: true,
          watch: true,
          dependencies: ['b'],
        ),
        BuildPackage(name: 'b', path: '/g/a/b', watch: true),
      });
      final nodes = {
        'a': FakeNodeWatcher(buildPackages['a']!)..markReady(),
        'b': FakeNodeWatcher(buildPackages['b']!)..markReady(),
      };
      final watcher = BuildPackagesWatcher(
        buildPackages,
        watch: (node) {
          return nodes[node.name]!;
        },
      );

      final events = <AssetChange>[];
      unawaited(watcher.watch().forEach(events.add));
      await watcher.ready;

      nodes['a']!.emitAdd('b/lib/b.dart');
      nodes['b']!.emitAdd('lib/b.dart');

      await pumpEventQueue();

      expect(events, [AssetChange(AssetId('b', 'lib/b.dart'), ChangeType.ADD)]);
    });

    test('should avoid watchers on pub dependencies', () {
      final buildPackages = BuildPackages.singlePackageBuild('a', {
        BuildPackage(
          name: 'a',
          path: '/g/a',
          isOutput: true,
          watch: true,
          dependencies: ['b'],
        ),
        BuildPackage(name: 'b', path: '/g/b', watch: false),
      });
      final nodes = {
        'a': FakeNodeWatcher(buildPackages['a']!),
        r'$sdk': FakeNodeWatcher(
          BuildPackage(name: '\$sdk', path: '', watch: true),
        ),
      };
      BuildPackageWatcher noBWatcher(BuildPackage node) {
        if (node.name == 'b') throw StateError('No watcher for B!');
        return nodes[node.name]!;
      }

      final watcher = BuildPackagesWatcher(buildPackages, watch: noBWatcher);

      unawaited(watcher.watch().drain());

      for (final node in nodes.values) {
        node.markReady();
      }

      expect(watcher.ready, completes);
    });

    test('ready waits for all node watchers to be ready', () async {
      final nodes = {
        'a': FakeNodeWatcher(buildPackages['a']!),
        'b': FakeNodeWatcher(buildPackages['b']!),
        r'$sdk': FakeNodeWatcher(
          BuildPackage(name: '\$sdk', path: '', watch: true),
        ),
      };
      final watcher = BuildPackagesWatcher(
        buildPackages,
        watch: (node) {
          return nodes[node.name]!;
        },
      );
      // We have to listen in order for `ready` to complete.
      unawaited(watcher.watch().drain());

      var done = false;
      unawaited(watcher.ready.then((_) => done = true));
      await Future<void>.value();

      for (final node in nodes.values) {
        expect(done, isFalse);
        node.markReady();
        await Future<void>.value();
      }

      await Future<void>.value();
      expect(done, isTrue);
    });
  });
}

class FakeNodeWatcher implements BuildPackageWatcher {
  @override
  final BuildPackage buildPackage;
  final _events = StreamController<AssetChange>();

  FakeNodeWatcher(this.buildPackage);

  @override
  Watcher get watcher => _watcher;
  final _watcher = _FakeWatcher();

  void markReady() => _watcher._readyCompleter.complete();

  void emitAdd(String path) {
    _events.add(AssetChange(AssetId(buildPackage.name, path), ChangeType.ADD));
  }

  @override
  Stream<AssetChange> watch() => _events.stream;
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
  final _readyCompleter = Completer<void>();
}
