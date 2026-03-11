// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_runner/src/build/asset_graph/node.dart';
import 'package:build_runner/src/build/resolver/analysis_driver_filesystem.dart';
import 'package:test/test.dart';

void main() {
  late AnalysisDriverFilesystem filesystem;

  setUp(() {
    filesystem = AnalysisDriverFilesystem();
  });

  group('AnalysisDriverFilesystem', () {
    test('write then read', () {
      filesystem.writeFile('foo.txt', 'bar');
      expect(filesystem.read('foo.txt'), 'bar');
    });

    test('read without write throws', () {
      expect(() => filesystem.read('foo.txt'), throwsA(isA<Error>()));
    });

    test('write adds to changedPaths', () {
      filesystem.writeFile('foo.txt', 'bar');
      expect(filesystem.changedPaths, ['foo.txt']);
    });

    test('identical write does not add to changedPaths', () {
      filesystem.writeFile('foo.txt', 'bar');
      filesystem.clearChangedPaths();
      expect(filesystem.changedPaths, isEmpty);
      filesystem.writeFile('foo.txt', 'bar');
      expect(filesystem.changedPaths, isEmpty);
    });

    test('write updates `exists`', () {
      expect(filesystem.exists('foo.txt'), false);
      filesystem.writeFile('foo.txt', 'bar');
      expect(filesystem.exists('foo.txt'), true);
    });

    test('files change by phases', () {
      filesystem.startBuild([
        AssetNode.generated(
          AssetId.parse('a|lib/a.g.dart'),
          primaryInput: AssetId.parse('a|lib/a.dart'),
          phaseNumber: 1,
          isHidden: false,
        ),
        AssetNode.generated(
          AssetId.parse('b|lib/b.g.dart'),
          primaryInput: AssetId.parse('b|lib/b.dart'),
          phaseNumber: 2,
          isHidden: false,
        ),
      ]);

      filesystem.writeFile('/a/lib/a.g.dart', 'a');
      filesystem.writeFile('/b/lib/b.g.dart', 'b');
      filesystem.clearChangedPaths();

      expect(filesystem.exists('/a/lib/a.g.dart'), false);
      expect(filesystem.exists('/b/lib/b.g.dart'), false);

      filesystem.phase = 2;
      expect(filesystem.changedPaths, {'/a/lib/a.g.dart'});
      filesystem.clearChangedPaths();
      expect(filesystem.exists('/a/lib/a.g.dart'), true);
      expect(filesystem.exists('/b/lib/b.g.dart'), false);

      filesystem.phase = 3;
      expect(filesystem.changedPaths, {'/b/lib/b.g.dart'});
      filesystem.clearChangedPaths();
      expect(filesystem.exists('/a/lib/a.g.dart'), true);
      expect(filesystem.exists('/b/lib/b.g.dart'), true);

      filesystem.phase = 0;
      expect(filesystem.changedPaths, {'/a/lib/a.g.dart', '/b/lib/b.g.dart'});
      expect(filesystem.exists('/a/lib/a.g.dart'), false);
      expect(filesystem.exists('/b/lib/b.g.dart'), false);
    });
  });
}
