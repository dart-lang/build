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
      filesystem.write('foo.txt', 'bar');
      expect(filesystem.read('foo.txt'), 'bar');
    });

    test('read without write throws', () {
      expect(() => filesystem.read('foo.txt'), throwsA(isA<Error>()));
    });

    test('write adds to changedPaths', () {
      filesystem.write('foo.txt', 'bar');
      expect(filesystem.changedPaths, ['foo.txt']);
    });

    test('identical write does not add to changedPaths', () {
      filesystem.write('foo.txt', 'bar');
      filesystem.clearChangedPaths();
      expect(filesystem.changedPaths, isEmpty);
      filesystem.write('foo.txt', 'bar');
      expect(filesystem.changedPaths, isEmpty);
    });

    test('write updates `exists`', () {
      expect(filesystem.exists('foo.txt'), false);
      filesystem.write('foo.txt', 'bar');
      expect(filesystem.exists('foo.txt'), true);
    });

    test('startBuild removes disappeared generated files', () {
      filesystem.startBuild(
        [
          AssetNode.generated(
            AssetId.parse('a|lib/a.g.dart'),
            primaryInput: AssetId.parse('a|lib/a.dart'),
            phaseNumber: 1,
            isHidden: false,
          ),
        ],
        invalidatedSources: null,
      );
      filesystem.write('/a/lib/a.g.dart', 'a');
      filesystem.phase = 2;
      filesystem.clearChangedPaths();

      filesystem.startBuild([], invalidatedSources: const {});

      expect(filesystem.changedPaths, {'/a/lib/a.g.dart'});
      expect(filesystem.exists('/a/lib/a.g.dart'), false);
    });

    test('startBuild retains unchanged generated file contents', () {
      filesystem.startBuild(
        [
          AssetNode.generated(
            AssetId.parse('a|lib/a.g.dart'),
            primaryInput: AssetId.parse('a|lib/a.dart'),
            phaseNumber: 1,
            isHidden: false,
          ),
        ],
        invalidatedSources: null,
      );
      filesystem.write('/a/lib/a.g.dart', 'a');
      filesystem.phase = 2;
      filesystem.clearChangedPaths();

      filesystem.startBuild(
        [
          AssetNode.generated(
            AssetId.parse('a|lib/a.g.dart'),
            primaryInput: AssetId.parse('a|lib/a.dart'),
            phaseNumber: 1,
            isHidden: false,
          ),
        ],
        invalidatedSources: const {},
      );

      expect(filesystem.read('/a/lib/a.g.dart'), 'a');
      expect(filesystem.changedPaths, isEmpty);
    });

    test('write with changed generated content across builds updates file and '
        'changedPaths', () {
      filesystem.startBuild(
        [
          AssetNode.generated(
            AssetId.parse('a|lib/a.g.dart'),
            primaryInput: AssetId.parse('a|lib/a.dart'),
            phaseNumber: 1,
            isHidden: false,
          ),
        ],
        invalidatedSources: null,
      );
      filesystem.write('/a/lib/a.g.dart', 'before');
      filesystem.phase = 2;
      filesystem.clearChangedPaths();

      filesystem.startBuild(
        [
          AssetNode.generated(
            AssetId.parse('a|lib/a.g.dart'),
            primaryInput: AssetId.parse('a|lib/a.dart'),
            phaseNumber: 1,
            isHidden: false,
          ),
        ],
        invalidatedSources: const {},
      );
      filesystem.write('/a/lib/a.g.dart', 'after');

      expect(filesystem.read('/a/lib/a.g.dart'), 'after');
      expect(filesystem.changedPaths, {'/a/lib/a.g.dart'});
    });

    test('initial build clears all cached contents', () {
      filesystem.startBuild(
        [
          AssetNode.generated(
            AssetId.parse('a|lib/a.g.dart'),
            primaryInput: AssetId.parse('a|lib/a.dart'),
            phaseNumber: 1,
            isHidden: false,
          ),
        ],
        invalidatedSources: null,
      );
      filesystem.write('/a/lib/a.dart', 'class A {}');
      filesystem.write('/a/lib/a.g.dart', 'generated');
      filesystem.phase = 2;
      filesystem.clearChangedPaths();

      filesystem.startBuild(
        [
          AssetNode.generated(
            AssetId.parse('a|lib/a.g.dart'),
            primaryInput: AssetId.parse('a|lib/a.dart'),
            phaseNumber: 1,
            isHidden: false,
          ),
        ],
        invalidatedSources: null,
      );

      expect(filesystem.exists('/a/lib/a.dart'), isFalse);
      expect(filesystem.exists('/a/lib/a.g.dart'), isFalse);
      expect(filesystem.changedPaths, {
        '/a/lib/a.dart',
        '/a/lib/a.g.dart',
      });
    });

    test('incremental build removes only invalidated source contents', () {
      filesystem.write('/a/foo.txt', 'bar');
      filesystem.write('/b/bar.txt', 'baz');
      filesystem.clearChangedPaths();

      filesystem.startBuild(
        const [],
        invalidatedSources: {AssetId.parse('a|foo.txt')},
      );

      expect(filesystem.exists('/a/foo.txt'), isFalse);
      expect(filesystem.exists('/b/bar.txt'), isTrue);
      expect(filesystem.changedPaths, {'/a/foo.txt'});
    });

    test('startBuild reports visibility changes for retained generated '
        'files', () {
      filesystem.startBuild(
        [
          AssetNode.generated(
            AssetId.parse('a|lib/a.g.dart'),
            primaryInput: AssetId.parse('a|lib/a.dart'),
            phaseNumber: 1,
            isHidden: false,
          ),
        ],
        invalidatedSources: null,
      );
      filesystem.write('/a/lib/a.g.dart', 'a');
      filesystem.phase = 2;
      filesystem.clearChangedPaths();

      filesystem.startBuild(
        [
          AssetNode.generated(
            AssetId.parse('a|lib/a.g.dart'),
            primaryInput: AssetId.parse('a|lib/a.dart'),
            phaseNumber: 3,
            isHidden: false,
          ),
        ],
        invalidatedSources: const {},
      );

      expect(filesystem.changedPaths, {'/a/lib/a.g.dart'});
      expect(filesystem.exists('/a/lib/a.g.dart'), false);
    });

    test('files change by phases', () {
      filesystem.startBuild(
        [
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
        ],
        invalidatedSources: null,
      );

      filesystem.write('/a/lib/a.g.dart', 'a');
      filesystem.write('/b/lib/b.g.dart', 'b');
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

extension _AnalysisDriverFilesystemExtensions on AnalysisDriverFilesystem {
  void write(String path, String content) {
    writeContent(
      BuildRunnerFileContent(path, true, content, content.hashCode.toString()),
    );
  }
}
