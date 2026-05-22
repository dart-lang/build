// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:build/build.dart';
import 'package:build_runner/src/build/library_cycle_graph/phased_value.dart';
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
      expect(filesystem.read('/a/lib/foo.txt'), 'bar');
    });

    test('read without write throws', () {
      expect(() => filesystem.read('/a/lib/foo.txt'), throwsA(isA<Error>()));
    });

    test('write adds to changedPaths', () {
      filesystem.write('foo.txt', 'bar');
      expect(filesystem.changedPaths, ['/a/lib/foo.txt']);
    });

    test('identical write does not add to changedPaths', () {
      filesystem.write('foo.txt', 'bar');
      filesystem.clearChangedPaths();
      expect(filesystem.changedPaths, isEmpty);
      filesystem.write('foo.txt', 'bar');
      expect(filesystem.changedPaths, isEmpty);
    });

    test('different write in the same build asserts', () {
      filesystem.write('foo.txt', 'bar');
      expect(
        () => filesystem.write('foo.txt', 'baz'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('write updates `exists`', () {
      expect(filesystem.exists('/a/lib/foo.txt'), false);
      filesystem.write('foo.txt', 'bar');
      expect(filesystem.exists('/a/lib/foo.txt'), true);
    });

    test('startBuild removes disappeared generated files', () {
      filesystem.startBuild(invalidatedSources: null);
      filesystem.write('/a/lib/a.g.dart', 'a');
      filesystem.phase = 2;
      filesystem.clearChangedPaths();

      filesystem.startBuild(invalidatedSources: {AssetId.parse('a|lib/a.g.dart')});

      expect(filesystem.changedPaths, {'/a/lib/a.g.dart'});
      expect(filesystem.exists('/a/lib/a.g.dart'), false);
    });

    test('startBuild retains unchanged generated file contents', () {
      filesystem.startBuild(invalidatedSources: null);
      filesystem.write('/a/lib/a.g.dart', 'a');
      filesystem.phase = 2;
      filesystem.clearChangedPaths();

      filesystem.startBuild(invalidatedSources: const {});

      expect(filesystem.read('/a/lib/a.g.dart'), 'a');
      expect(filesystem.changedPaths, isEmpty);
    });

    test('invisible files do not exist', () {
      filesystem.startBuild(invalidatedSources: null);
      filesystem.write('/a/lib/a.g.dart', 'a', expiresAfter: 1);
      filesystem.phase = 0;

      expect(filesystem.exists('/a/lib/a.g.dart'), false);
    });

    test('visible files exist', () {
      filesystem.startBuild(invalidatedSources: null);
      filesystem.write('/a/lib/a.g.dart', 'a', expiresAfter: 1);
      filesystem.phase = 2;

      expect(filesystem.exists('/a/lib/a.g.dart'), true);
    });

    test('visible files can be read', () {
      filesystem.startBuild(invalidatedSources: null);
      filesystem.write('/a/lib/a.g.dart', 'a', expiresAfter: 1);
      filesystem.phase = 2;

      expect(filesystem.read('/a/lib/a.g.dart'), 'a');
    });

    test('invisible files cannot be read', () {
      filesystem.startBuild(invalidatedSources: null);
      filesystem.write('/a/lib/a.g.dart', 'a', expiresAfter: 1);
      filesystem.phase = 0;

      expect(() => filesystem.read('/a/lib/a.g.dart'), throwsStateError);
    });

    test('phase change invalidates/validates generated files', () {
      filesystem.startBuild(invalidatedSources: null);
      filesystem.write('/a/lib/a.g.dart', 'a', expiresAfter: 1);
      filesystem.write('/b/lib/b.g.dart', 'b', expiresAfter: 2);
      filesystem.phase = 0;
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
  void write(String path, String content, {int? expiresAfter}) {
    final fullPath = path.startsWith('/') ? path : '/a/lib/$path';
    final asset = AnalysisDriverFilesystem.parseAsset(Uri.parse('file://$fullPath'))!;
    final fileContent = BuildRunnerFileContent(fullPath, true, content, content.hashCode.toString());
    final phased = expiresAfter == null
        ? PhasedValue.fixed(fileContent)
        : PhasedValue<FileContent>((b) {
            b.values.add(ExpiringValue<FileContent>(BuildRunnerFileContent.missing(fullPath), expiresAfter: expiresAfter));
            b.values.add(ExpiringValue<FileContent>(fileContent));
          });
    writePhasedContent(asset, phased);
  }
}
