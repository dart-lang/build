// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/package_graph/package_graph.dart';
import 'package:build_runner/src/watcher/asset_change.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

void main() {
  group('AssetChange', () {
    test('should be equal if asset and type are equivalent', () {
      AssetId asset(String name) => new AssetId(name, 'lib/$asset.dart');
      final pkgA1 = asset('a');
      final pkgA2 = asset('a');

      final change1 = new AssetChange(pkgA1, ChangeType.ADD);
      final change2 = new AssetChange(pkgA2, ChangeType.ADD);

      expect(change1, equals(change2));

      final change3 = new AssetChange(pkgA1, ChangeType.MODIFY);
      expect(change1, isNot(equals(change3)));

      final pkgB = asset('b');
      final change4 = new AssetChange(pkgB, ChangeType.ADD);
      expect(change1, isNot(equals(change4)));
    });

    test('should support relative paths', () {
      final pkgBar = path.join('/', 'foo', 'bar');
      final barFile = path.join('lib', 'bar.dart');
      final nodeBar = new PackageNode.noPubspec('bar', pkgBar);

      final event = new WatchEvent(ChangeType.ADD, barFile);
      final change = new AssetChange.fromEvent(nodeBar, event);

      expect(change.id.package, 'bar');
      expect(change.id.path, path.join('lib', 'bar.dart'));
    });

    test('should normalize absolute paths to relative', () {
      final pkgBar = path.join('/', 'foo', 'bar');
      final barFile = path.join('/', 'foo', 'bar', 'lib', 'bar.dart');

      final nodeBar = new PackageNode.noPubspec('bar', pkgBar);
      final event = new WatchEvent(ChangeType.ADD, barFile);
      final change = new AssetChange.fromEvent(nodeBar, event);

      expect(change.id.package, 'bar');
      expect(change.id.path, path.join('lib', 'bar.dart'));
    });
  });
}
