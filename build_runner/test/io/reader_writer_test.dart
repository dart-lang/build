// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
library;

import 'dart:io';

import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/io/reader_writer.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../common/common.dart';

void main() async {
  group('ReaderWriter', () {
    late BuildPackages buildPackages;
    late ReaderWriter readerWriter;
    late String tempDirectory;

    setUp(() async {
      final pubspecs = await Pubspecs.load();
      final tester = BuildRunnerTester(pubspecs);
      tempDirectory = tester.tempDirectory.path;

      tester.writePackage(
        name: 'basic_pkg',
        files: {
          'hello.txt': 'world\n',
          'lib/hello.txt': 'world\n',
          'web/hello.txt': 'world\n',
        },
        pathDependencies: ['a'],
      );
      tester.writePackage(
        name: 'a',
        files: {'lib/a.txt': 'A\n'},
        pathDependencies: [],
      );
      await tester.run('basic_pkg', 'dart pub get');

      buildPackages = await BuildPackages.forPath(
        p.join(tempDirectory, 'basic_pkg'),
      );
      readerWriter = ReaderWriter(buildPackages);
    });

    test('can read any application package files', () async {
      expect(
        await readerWriter.readAsString(makeAssetId('basic_pkg|hello.txt')),
        'world\n',
      );
      expect(
        await readerWriter.readAsString(makeAssetId('basic_pkg|lib/hello.txt')),
        'world\n',
      );
      expect(
        await readerWriter.readAsString(makeAssetId('basic_pkg|web/hello.txt')),
        'world\n',
      );
    });

    test('can read package dependency files in the lib dir', () async {
      expect(
        await readerWriter.readAsString(makeAssetId('a|lib/a.txt')),
        'A\n',
      );
    });

    test('can check for existence of any application package files', () async {
      expect(
        await readerWriter.canRead(makeAssetId('basic_pkg|hello.txt')),
        isTrue,
      );
      expect(
        await readerWriter.canRead(makeAssetId('basic_pkg|lib/hello.txt')),
        isTrue,
      );
      expect(
        await readerWriter.canRead(makeAssetId('basic_pkg|web/hello.txt')),
        isTrue,
      );

      expect(
        await readerWriter.canRead(makeAssetId('basic_pkg|a.txt')),
        isFalse,
      );
      expect(
        await readerWriter.canRead(makeAssetId('basic_pkg|lib/a.txt')),
        isFalse,
      );
    });

    test(
      'can check for existence of package dependency files in lib',
      () async {
        expect(await readerWriter.canRead(makeAssetId('a|lib/a.txt')), isTrue);
        expect(await readerWriter.canRead(makeAssetId('a|lib/b.txt')), isFalse);
      },
    );

    test('throws when attempting to read a non-existent file', () async {
      expect(
        () => readerWriter.readAsString(makeAssetId('basic_pkg|foo.txt')),
        throwsA(assetNotFoundException),
      );
      expect(
        () => readerWriter.readAsString(makeAssetId('a|lib/b.txt')),
        throwsA(assetNotFoundException),
      );
      expect(
        () => readerWriter.readAsString(makeAssetId('foo|lib/bar.txt')),
        throwsA(packageNotFoundException),
      );
    });

    test('can list files based on glob', () async {
      expect(
        await readerWriter.assetFinder
            .find(Glob('{lib,web}/**'), package: 'basic_pkg')
            .toList(),
        unorderedEquals([
          makeAssetId('basic_pkg|lib/hello.txt'),
          makeAssetId('basic_pkg|web/hello.txt'),
        ]),
      );
    });

    test('can compute digests', () async {
      expect(
        await readerWriter.digest(makeAssetId('basic_pkg|hello.txt')),
        isNotNull,
      );
    });

    test('digests are different for different file contents', () async {
      final helloDigest = await readerWriter.digest(
        makeAssetId('basic_pkg|lib/hello.txt'),
      );
      final aDigest = await readerWriter.digest(makeAssetId('a|lib/a.txt'));
      expect(helloDigest, isNot(equals(aDigest)));
    });

    test(
      'digests are identical for identical file contents and assets',
      () async {
        final helloDigest = await readerWriter.digest(
          makeAssetId('basic_pkg|lib/hello.txt'),
        );
        final aDigest = await readerWriter.digest(
          makeAssetId('basic_pkg|lib/hello.txt'),
        );
        expect(helloDigest, equals(aDigest));
      },
    );

    test('digests are different for identical file contents and different '
        'assets', () async {
      final helloDigest = await readerWriter.digest(
        makeAssetId('basic_pkg|lib/hello.txt'),
      );
      final aDigest = await readerWriter.digest(
        makeAssetId('basic_pkg|web/hello.txt'),
      );
      expect(helloDigest, isNot(equals(aDigest)));
    });

    test('can read from the SDK', () async {
      expect(
        await readerWriter.canRead(makeAssetId(r'$sdk|lib/libraries.json')),
        true,
      );
    });

    test('can output and delete files in the application package', () async {
      final id = makeAssetId('basic_pkg|test_file.txt');
      final content = 'test';
      await readerWriter.writeAsString(id, content);
      final file = File(path.join(tempDirectory, id.package, id.path));
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), content);

      await readerWriter.delete(id);
      expect(await file.exists(), isFalse);
    });
  });
}
