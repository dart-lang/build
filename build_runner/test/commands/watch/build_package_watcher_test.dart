// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build/build.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/commands/watch/asset_change.dart';
import 'package:build_runner/src/commands/watch/build_package_watcher.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

void main() {
  group('PackageNodeWatcher', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync();
    });

    tearDown(() {
      tmpDir.deleteSync(recursive: true);
    });

    void initFiles(BuildPackage node) {
      File(p.join(node.path, 'lib', '2.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync('2');
      File(p.join(node.path, 'lib', '3.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync('3');
    }

    void modifyFiles(BuildPackage node) {
      File(p.join(node.path, 'lib', '1.dart')).createSync(recursive: true);
      File(p.join(node.path, 'lib', '2.dart')).writeAsStringSync('2+');
      File(p.join(node.path, 'lib', '3.dart')).deleteSync();
    }

    test('should emit a changed asset', () async {
      final node = BuildPackage(
        name: 'a',
        path: p.join(tmpDir.path, 'a'),
        watch: true,
      );
      final nodeWatcher = BuildPackageWatcher(node);

      initFiles(node);

      expect(
        nodeWatcher.watch(),
        emitsInAnyOrder([
          AssetChange(AssetId('a', 'lib/1.dart'), ChangeType.ADD),
          AssetChange(AssetId('a', 'lib/2.dart'), ChangeType.MODIFY),
          AssetChange(AssetId('a', 'lib/3.dart'), ChangeType.REMOVE),
        ]),
      );

      await nodeWatcher.watcher.ready;
      modifyFiles(node);
    });

    test('should also respect relative watch URLs', () async {
      final node = BuildPackage(
        name: 'a',
        path: p.relative(p.join(tmpDir.path, 'a'), from: p.current),
        watch: true,
      );
      final nodeWatcher = BuildPackageWatcher(node);

      initFiles(node);

      expect(
        nodeWatcher.watch(),
        emitsInAnyOrder([
          AssetChange(AssetId('a', 'lib/1.dart'), ChangeType.ADD),
          AssetChange(AssetId('a', 'lib/2.dart'), ChangeType.MODIFY),
          AssetChange(AssetId('a', 'lib/3.dart'), ChangeType.REMOVE),
        ]),
      );

      await nodeWatcher.watcher.ready;
      modifyFiles(node);
    });
  });
}
