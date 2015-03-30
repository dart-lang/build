// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_gen.test.io_test;

import 'package:unittest/unittest.dart';
import 'package:source_gen/src/io.dart';
import 'package:path/path.dart' as p;

import 'test_utils.dart';

void main() {
  test('expandFileListToIncludePeers', () {
    var examplePath = p.join(getPackagePath(), 'example');
    var jsonPath = p.join(examplePath, 'data.json');

    var things = expandFileListToIncludePeers([jsonPath])
        .map((path) => p.relative(path, from: examplePath))
        .toList();

    expect(things,
        unorderedEquals(['data.json', 'example.dart', 'example.g.dart']));
  });

  test('find files', () {
    var testFilesPath = p.join(getPackagePath(), 'test', 'test_files');

    return getDartFiles(testFilesPath).then((files) {
      expect(files, hasLength(4));
    });
  });

  test('search with one sub directory', () async {
    var testFilesPath = p.join(getPackagePath(), 'test');

    var files = await getDartFiles(testFilesPath, searchList: ['test_files']);

    expect(files, hasLength(4));
  });

  test('search with one sub directory and one file', () async {
    var testFilesPath = p.join(getPackagePath(), 'test');

    var files = await getDartFiles(testFilesPath,
        searchList: ['test_files', 'io_test.dart']);

    expect(files, hasLength(5));
  });

  test('search with one file', () async {
    var testFilesPath = p.join(getPackagePath(), 'test');

    var files = await getDartFiles(testFilesPath, searchList: ['io_test.dart']);

    expect(files, hasLength(1));
  });

  test('search with none existent file', () async {
    var testFilesPath = p.join(getPackagePath(), 'test');

    var files =
        await getDartFiles(testFilesPath, searchList: ['no_file_here.dart']);

    expect(files, hasLength(0));
  });

  group('redundant items fail', () {
    test('dir then contained file', () async {
      var testFilesPath = p.join(getPackagePath());

      var caught = false;
      return getDartFiles(testFilesPath,
          searchList: ['test', 'test/io_test.dart']).catchError((error) {
        expect(error, isArgumentError);
        caught = true;
      }).whenComplete(() {
        expect(caught, isTrue);
      });
    });

    test('dir then contained dir', () async {
      var testFilesPath = p.join(getPackagePath());

      var caught = false;
      return getDartFiles(testFilesPath,
          searchList: ['test', 'test/test_files']).catchError((error) {
        expect(error, isArgumentError);
        caught = true;
      }).whenComplete(() {
        expect(caught, isTrue);
      });
    });

    test('file then containing dir', () async {
      var testFilesPath = p.join(getPackagePath());

      var caught = false;
      return getDartFiles(testFilesPath,
          searchList: ['test/io_test.dart', 'test']).catchError((error) {
        expect(error, isArgumentError);
        caught = true;
      }).whenComplete(() {
        expect(caught, isTrue);
      });
    });

    test('dir then containing dir', () async {
      var testFilesPath = p.join(getPackagePath());

      var caught = false;
      return getDartFiles(testFilesPath,
          searchList: ['test/test_files', 'test']).catchError((error) {
        expect(error, isArgumentError);
        caught = true;
      }).whenComplete(() {
        expect(caught, isTrue);
      });
    });
  });
}
