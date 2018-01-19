// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import 'package:build_runner/src/package_graph/package_graph.dart';
import 'package:build_runner/src/watcher/asset_change.dart';
import 'package:build_runner/src/watcher/node_watcher.dart';

void main() {
  group('PackageNodeWatcher', () {
    Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync();
    });

    tearDown(() {
      tmpDir.deleteSync(recursive: true);
    });

    void initFiles(PackageNode node) {
      new File(p.join(node.path, 'lib', '2.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync('2');
      new File(p.join(node.path, 'lib', '3.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync('3');
    }

    void modifyFiles(PackageNode node) {
      new File(p.join(node.path, 'lib', '1.dart')).createSync(recursive: true);
      new File(p.join(node.path, 'lib', '2.dart')).writeAsStringSync('2+');
      new File(p.join(node.path, 'lib', '3.dart')).deleteSync();
    }

    test('should emit a changed asset', () async {
      var node = new PackageNode('a', p.join(tmpDir.path, 'a'), null);
      var nodeWatcher = new PackageNodeWatcher(node);

      initFiles(node);

      expect(
        nodeWatcher.watch('lib'),
        emitsInAnyOrder([
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

      await nodeWatcher.watcher.ready;
      modifyFiles(node);
    });

    test('should also respect relative watch URLs', () async {
      var node = new PackageNode(
          'a', p.relative(p.join(tmpDir.path, 'a'), from: p.current), null);
      var nodeWatcher = new PackageNodeWatcher(node);

      initFiles(node);

      expect(
        nodeWatcher.watch('lib'),
        emitsInAnyOrder([
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

      await nodeWatcher.watcher.ready;
      modifyFiles(node);
    });
  });
}
