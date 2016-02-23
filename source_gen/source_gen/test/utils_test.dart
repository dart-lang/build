// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('!browser')
library source_gen.test.utils_test;

import 'package:analyzer/src/generated/engine.dart';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:source_gen/src/utils.dart';

import 'src/io.dart';
import 'test_utils.dart';

void main() {
  group('libraries for files', () {
    AnalysisContext ctx;

    setUp(() async {
      if (ctx == null) {
        var projectPath = getPackagePath();
        var foundFiles = await getDartFiles(projectPath,
            searchList: [p.join(getPackagePath(), 'test', 'test_files')]);

        ctx = await getAnalysisContextForProjectPath(projectPath, foundFiles);
      }
    });

    test('part -> library', () {
      var libs = getLibraries(ctx, [_part1path]);

      expect(libs.single.name, _lib1Name);
    });

    test('library -> library', () {
      var libs = getLibraries(ctx, [_lib1path]);

      expect(libs.single.name, _lib1Name);
    });

    test('part + library -> library', () {
      var libs = getLibraries(ctx, [_part1path, _lib1path]);

      expect(libs.single.name, _lib1Name);
    });

    test('part2 + library -> library + library 2', () {
      var libs = getLibraries(ctx, [_part2path, _lib1path]);

      expect(libs.map((lib) => lib.name).toList(),
          unorderedEquals([_lib1Name, _lib2Name]));
    });

    test('part + library2 -> library + library 2', () {
      var libs = getLibraries(ctx, [_part1path, _lib2path]);

      expect(libs.map((lib) => lib.name).toList(),
          unorderedEquals([_lib1Name, _lib2Name]));
    });

    test('everything -> library + library 2', () {
      var libs =
          getLibraries(ctx, [_lib1path, _lib2path, _part1path, _part2path]);

      expect(libs.map((lib) => lib.name).toList(),
          unorderedEquals([_lib1Name, _lib2Name]));
    });
  });

  group('find part of', () {
    test("after comments", () {
      var index = findPartOf('''// commant
//more comment
part of foo;''');
      expect(index, 'part of foo;');
    });

    test('after comments and whitespace', () {
      var index = findPartOf('''

// that two blank linse
// a comment line

// another blank line
part of monkey;
class bar{}''');
      expect(index, 'part of monkey;\nclass bar{}');
    });

    test("not there", () {
      var index = findPartOf('//\n//\n\n');
      expect(index, null);
    });
  });
}

final _testFilesLib = p.join(getPackagePath(), 'test', 'test_files');

final _lib1Name = 'source_gen.test.annotation_test.classes';
final _lib2Name = 'source_gen.test.annotation_test.defs';

final _lib1path = p.join(_testFilesLib, 'annotated_classes.dart');
final _part1path = p.join(_testFilesLib, 'annotated_classes_part.dart');
final _lib2path = p.join(_testFilesLib, 'annotations.dart');
final _part2path = p.join(_testFilesLib, 'annotation_part.dart');
