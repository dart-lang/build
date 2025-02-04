// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_resolvers/src/analysis_driver_filesystem.dart';
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

    test('delete adds to changedPaths', () {
      filesystem.writeFile('foo.txt', 'bar');
      filesystem.clearChangedPaths();
      expect(filesystem.changedPaths, isEmpty);
      filesystem.deleteFile('foo.txt');
      expect(filesystem.changedPaths, ['foo.txt']);
    });

    test('delete of missing file does not add to changedPaths', () {
      filesystem.deleteFile('foo.txt');
      expect(filesystem.changedPaths, isEmpty);
    });
  });
}
