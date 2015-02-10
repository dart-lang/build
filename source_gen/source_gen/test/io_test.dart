library source_gen.test.io_test;

import 'package:unittest/unittest.dart';
import 'package:source_gen/src/io.dart';
import 'package:path/path.dart' as p;

import 'test_utils.dart';

void main() {
  test('find files', () {
    var testFilesPath = p.join(getPackagePath(), 'test', 'test_files');

    return getFiles(testFilesPath).toList().then((files) {
      expect(files, hasLength(4));
    });
  });

  test('search with one sub directory', () async {
    var testFilesPath = p.join(getPackagePath(), 'test');

    var files =
        await getFiles(testFilesPath, searchList: ['test_files']).toList();

    expect(files, hasLength(4));
  });

  test('search with one sub directory and one file', () async {
    var testFilesPath = p.join(getPackagePath(), 'test');

    var files = await getFiles(testFilesPath,
        searchList: ['test_files', 'io_test.dart']).toList();

    expect(files, hasLength(5));
  });

  test('search with one file', () async {
    var testFilesPath = p.join(getPackagePath(), 'test');

    var files =
        await getFiles(testFilesPath, searchList: ['io_test.dart']).toList();

    expect(files, hasLength(1));
  });

  test('search with none existent file', () async {
    var testFilesPath = p.join(getPackagePath(), 'test');

    var files = await getFiles(testFilesPath, searchList: ['no_file_here.dart'])
        .toList();

    expect(files, hasLength(0));
  });

  group('redundant items fail', () {
    test('dir then contained file', () async {
      var testFilesPath = p.join(getPackagePath());

      var caught = false;
      return getFiles(testFilesPath, searchList: ['test', 'test/io_test.dart'])
          .toList()
          .catchError((error) {
        expect(error, isArgumentError);
        caught = true;
      }).whenComplete(() {
        expect(caught, isTrue);
      });
    });

    test('dir then contained dir', () async {
      var testFilesPath = p.join(getPackagePath());

      var caught = false;
      return getFiles(testFilesPath, searchList: ['test', 'test/test_files'])
          .toList()
          .catchError((error) {
        expect(error, isArgumentError);
        caught = true;
      }).whenComplete(() {
        expect(caught, isTrue);
      });
    });

    test('file then containing dir', () async {
      var testFilesPath = p.join(getPackagePath());

      var caught = false;
      return getFiles(testFilesPath, searchList: ['test/io_test.dart', 'test'])
          .toList()
          .catchError((error) {
        expect(error, isArgumentError);
        caught = true;
      }).whenComplete(() {
        expect(caught, isTrue);
      });
    });

    test('dir then containing dir', () async {
      var testFilesPath = p.join(getPackagePath());

      var caught = false;
      return getFiles(testFilesPath, searchList: ['test/test_files', 'test'])
          .toList()
          .catchError((error) {
        expect(error, isArgumentError);
        caught = true;
      }).whenComplete(() {
        expect(caught, isTrue);
      });
    });
  });
}
