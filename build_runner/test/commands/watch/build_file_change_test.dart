// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/build_file.dart';
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

      final change1 = BuildFileChange(AssetFile.source(pkgA1), ChangeType.ADD);
      final change2 = BuildFileChange(AssetFile.source(pkgA2), ChangeType.ADD);

      expect(change1, equals(change2));

      final change3 = BuildFileChange(
        AssetFile.source(pkgA1),
        ChangeType.MODIFY,
      );
      expect(change1, isNot(equals(change3)));

      final pkgB = asset('b');
      final change4 = BuildFileChange(AssetFile.source(pkgB), ChangeType.ADD);
      expect(change1, isNot(equals(change4)));
    });

    test('should convert events for source, internal, and cache files', () {
      final pkgBar = p.join('/', 'foo', 'bar');
      final nodeBar = BuildPackage(name: 'bar', path: pkgBar, watch: true);

      // Source file
      final sourceFile = p.join(pkgBar, 'lib', 'bar.dart');
      final sourceChange = BuildFileChange.fromEvent(
        nodeBar,
        WatchEvent(ChangeType.ADD, sourceFile),
      );
      expect(
        sourceChange.file,
        equals(AssetFile.source(AssetId('bar', 'lib/bar.dart'))),
      );
      expect(sourceChange.id, equals(AssetId('bar', 'lib/bar.dart')));

      // Internal file
      final internalFile = p.join(pkgBar, '.dart_tool', 'package_config.json');
      final internalChange = BuildFileChange.fromEvent(
        nodeBar,
        WatchEvent(ChangeType.MODIFY, internalFile),
      );
      expect(
        internalChange.file,
        equals(InternalFile('bar', '.dart_tool/package_config.json')),
      );
      expect(internalChange.id, isNull);

      // Cache file for dependency
      final cacheFile = p.join(
        pkgBar,
        '.dart_tool',
        'build',
        'generated',
        'dep',
        'lib',
        'dep.g.dart',
      );
      final cacheChange = BuildFileChange.fromEvent(
        nodeBar,
        WatchEvent(ChangeType.REMOVE, cacheFile),
      );
      expect(
        cacheChange.file,
        equals(AssetFile.cache(AssetId('dep', 'lib/dep.g.dart'))),
      );
      expect(cacheChange.id, equals(AssetId('dep', 'lib/dep.g.dart')));
    });

    test('throws if path is outside package', () {
      final pkgBar = p.join('/', 'foo', 'bar');
      final otherFile = p.join('/', 'foo', 'baz', 'lib', 'baz.dart');

      final nodeBar = BuildPackage(name: 'bar', path: pkgBar, watch: true);
      final event = WatchEvent(ChangeType.ADD, otherFile);
      expect(
        () => BuildFileChange.fromEvent(nodeBar, event),
        throwsArgumentError,
      );
    });
  });
}
