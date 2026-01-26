// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('resolveSource can resolve', () {
    test('a simple dart file', () async {
      final libExample = await resolveSource(r'''
        library example;

        class Foo {}
      ''', (resolver) => resolver.findLibraryNotNull('example'));
      expect(libExample.getClass('Foo'), isNotNull);
    });

    test('a simple dart file with dart: dependencies', () async {
      final libExample = await resolveSource(r'''
        library example;

        import 'dart:collection';

        abstract class Foo implements LinkedHashMap {}
      ''', (resolver) => resolver.findLibraryNotNull('example'));
      final classFoo = libExample.getClass('Foo')!;
      expect(
        classFoo.allSupertypes.map(_toStringId),
        contains('dart:collection#LinkedHashMap'),
      );
    });

    test('a simple dart file package: dependencies', () async {
      final libExample = await resolveSource(
        r'''
        library example;

        import 'package:collection/collection.dart';

        abstract class Foo implements Equality {}
      ''',
        nonInputsToReadFromFilesystem: {
          AssetId('collection', 'lib/collection.dart'),
          AssetId('collection', 'lib/src/equality.dart'),
        },
        (resolver) => resolver.findLibraryNotNull('example'),
      );
      final classFoo = libExample.getClass('Foo')!;
      expect(
        classFoo.allSupertypes.map(_toStringId),
        contains(endsWith(':collection#Equality')),
      );
    });

    test('multiple assets, some mock, some on disk', () async {
      final real = 'build_test|test/_files/example_lib.dart';
      final mock = 'build_test|test/_files/not_really_here.dart';
      final library = await resolveSources(
        {
          real: useAssetReader,
          mock: r'''
            // This is a fake library that we're mocking.
            library example;

            // This is a real on-disk library we are using.
            import 'example_lib.dart';

            class ExamplePrime extends Example {}
          ''',
        },
        (resolver) => resolver.findLibraryNotNull('example'),
        resolverFor: mock,
      );
      final type = library.getClass('ExamplePrime');
      expect(type, isNotNull);
      expect(type!.supertype!.element.name, 'Example');
    });

    test('can do expects inside the action', () async {
      await resolveSource(
        r'''
        library example;

        import 'package:collection/collection.dart';

        abstract class Foo implements Equality {}
      ''',
        nonInputsToReadFromFilesystem: {
          AssetId('collection', 'lib/collection.dart'),
          AssetId('collection', 'lib/src/equality.dart'),
        },
        (resolver) async {
          final libExample = await resolver.findLibraryNotNull('example');
          final classFoo = libExample.getClass('Foo')!;
          expect(
            classFoo.allSupertypes.map(_toStringId),
            contains(endsWith(':collection#Equality')),
          );
        },
      );
    });

    test('with specified language versions from a PackageConfig', () async {
      final packageConfig = PackageConfig([
        Package(
          'a',
          Uri.file('/a/'),
          packageUriRoot: Uri.file('/a/lib/'),
          languageVersion: LanguageVersion(3, 5),
        ),
      ]);
      final libExample = await resolveSource(
        r'''
        library example;
        int x = 1_000;
      ''',
        (resolver) => resolver.findLibraryNotNull('example'),
        packageConfig: packageConfig,
        inputId: AssetId('a', 'invalid.dart'),
      );
      final errors =
          await libExample.session.getErrors(
                libExample.firstFragment.source.fullName,
              )
              as ErrorsResult;
      expect(
        errors.diagnostics.map((e) => e.message),
        contains(
          contains(
            'This requires the \'digit-separators\' language feature to be '
            'enabled.',
          ),
        ),
      );
    });

    test('all sources from real filesystem', () async {
      await resolveSource(
        r'''
        library example;

        import 'package:collection/collection.dart';

        abstract class Foo implements Equality {}
      ''',
        readAllSourcesFromFilesystem: true,
        (resolver) async {
          final libExample = await resolver.findLibraryNotNull('example');
          final classFoo = libExample.getClass('Foo')!;
          expect(
            classFoo.allSupertypes.map(_toStringId),
            contains(endsWith(':collection#Equality')),
          );
        },
      );
    });

    test('all sources from real filesystem skips asset graph', () async {
      // `resolveSources` should ignore `asset_graph.json` when reading from the
      // real filesystem as it would cause surprising effects related to the
      // latest real build, for example deletion of generated files.

      // To check if `asset_graph.json` is read from the real filesystem
      // do a test build then write `asset_graph.json` to the real filesystem.
      // Then do an identical build. If `asset_graph.json` is used then the
      // identical build will be skipped.

      final sources = {'build_test|test/some_file.dart': ''};

      // Generate and write `asset_graph.json`.
      late String assetGraphContent;
      await resolveSources(
        sources,
        readAllSourcesFromFilesystem: true,
        assetReaderChecks: (testReaderWriter) {
          assetGraphContent = testReaderWriter.testing.readString(
            AssetId('build_test', '.dart_tool/build/asset_graph.json'),
          );
        },
        (resolver) async {},
      );
      final packageConfig = await loadPackageConfigUri(
        (await Isolate.packageConfig)!,
      );
      final path = packageConfig['build_test']!.root;
      final file = File(
        p.join(path.toFilePath(), '.dart_tool/build/asset_graph.json'),
      );
      file.createSync(recursive: true);
      file.writeAsStringSync(assetGraphContent);

      // It should make no difference, the identical build should run again.
      var ranSecondTime = false;
      await resolveSources(sources, readAllSourcesFromFilesystem: true, (
        resolver,
      ) async {
        ranSecondTime = true;
      });
      expect(ranSecondTime, true);
    });
  });

  group('should resolveAsset', () {
    test('asset:build_test/test/_files/example_lib.dart', () async {
      final asset = AssetId('build_test', 'test/_files/example_lib.dart');
      final libExample = await resolveAsset(
        asset,
        (resolver) => resolver.findLibraryNotNull('example_lib'),
      );
      expect(libExample.getClass('Example'), isNotNull);
    });
  });

  group('error handling', () {
    test('getting the library for a part file', () async {
      final partAsset = AssetId('build_test', 'test/_files/example_part.dart');
      await resolveAsset(partAsset, (resolver) async {
        expect(
          () => resolver.libraryFor(partAsset),
          throwsA(
            isA<NonLibraryAssetException>().having(
              (e) => e.assetId,
              'assetId',
              partAsset,
            ),
          ),
        );
      });
    });
  });
}

String _toStringId(InterfaceType t) =>
    '${t.element.library.uri.toString().split('/').first}#${t.element.name}';

extension on Resolver {
  Future<LibraryElement> findLibraryNotNull(String name) async {
    return (await findLibraryByName(name))!;
  }
}
