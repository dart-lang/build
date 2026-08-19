// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/commands/watch/build_file_change.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

void main() {
  group('BuildFileChange', () {
    test('should be equal if asset and type are equivalent', () {
      AssetId asset(String name) => AssetId(name, 'lib/$asset.dart');
      final pkgA1 = asset('a');
      final pkgA2 = asset('a');

      final change1 = BuildFileChange(pkgA1, ChangeType.ADD);
      final change2 = BuildFileChange(pkgA2, ChangeType.ADD);

      expect(change1, equals(change2));

      final change3 = BuildFileChange(pkgA1, ChangeType.MODIFY);
      expect(change1, isNot(equals(change3)));

      final pkgB = asset('b');
      final change4 = BuildFileChange(pkgB, ChangeType.ADD);
      expect(change1, isNot(equals(change4)));
    });

    test('should support relative paths', () {
      final pkgBar = p.join('/', 'foo', 'bar');
      final barFile = p.join(
        p.relative(pkgBar, from: p.current),
        'lib',
        'bar.dart',
      );
      final nodeBar = BuildPackage(name: 'bar', path: pkgBar, watch: true);

      final event = WatchEvent(ChangeType.ADD, barFile);
      final change = BuildFileChange.fromEvent(nodeBar, event);

      expect(change.id!.package, 'bar');
      expect(change.id!.path, p.join('lib', 'bar.dart'));
    });

    test('should normalize absolute paths to relative', () {
      final pkgBar = p.join('/', 'foo', 'bar');
      final barFile = p.join('/', 'foo', 'bar', 'lib', 'bar.dart');

      final nodeBar = BuildPackage(name: 'bar', path: pkgBar, watch: true);
      final event = WatchEvent(ChangeType.ADD, barFile);
      final change = BuildFileChange.fromEvent(nodeBar, event);

      expect(change.id!.package, 'bar');
      expect(change.id!.path, p.join('lib', 'bar.dart'));
    });
  });
}
