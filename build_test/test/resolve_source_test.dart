// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';

void main() {
  group('resolveSource can resolve', () {
    test('a simple dart file', () async {
      var libExample = await resolveSource(r'''
        library example;

        class Foo {}
      ''', (resolver) => resolver.findLibraryNotNull2('example'));
      expect(libExample.getClass2('Foo'), isNotNull);
    });

    test('a simple dart file with dart: dependencies', () async {
      var libExample = await resolveSource(r'''
        library example;

        import 'dart:collection';

        abstract class Foo implements LinkedHashMap {}
      ''', (resolver) => resolver.findLibraryNotNull2('example'));
      var classFoo = libExample.getClass2('Foo')!;
      expect(
        classFoo.allSupertypes.map(_toStringId),
        contains('dart:collection#LinkedHashMap'),
      );
    });

    test('a simple dart file package: dependencies', () async {
      var libExample = await resolveSource(r'''
        library example;

        import 'package:collection/collection.dart';

        abstract class Foo implements Equality {}
      ''', (resolver) => resolver.findLibraryNotNull2('example'));
      var classFoo = libExample.getClass2('Foo')!;
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
        (resolver) => resolver.findLibraryNotNull2('example'),
        resolverFor: mock,
      );
      final type = library.getClass2('ExamplePrime');
      expect(type, isNotNull);
      expect(type!.supertype!.element3.name3, 'Example');
    });

    test('waits for tearDown', () async {
      var resolverDone = Completer<void>();
      var resolver = await resolveSource(r'''
        library example;

        import 'package:collection/collection.dart';

        abstract class Foo implements Equality {}
      ''', (resolver) => resolver, tearDown: resolverDone.future);
      expect(
          await resolver.libraries2
              .any((library) => library.name3 == 'example'),
          true);
      var libExample = await resolver.findLibraryNotNull2('example');
      resolverDone.complete();
      var classFoo = libExample.getClass2('Foo')!;
      expect(
        classFoo.allSupertypes.map(_toStringId),
        contains(endsWith(':collection#Equality')),
      );
    });

    test('can do expects inside the action', () async {
      await resolveSource(r'''
        library example;

        import 'package:collection/collection.dart';

        abstract class Foo implements Equality {}
      ''', (resolver) async {
        var libExample = await resolver.findLibraryNotNull2('example');
        var classFoo = libExample.getClass2('Foo')!;
        expect(classFoo.allSupertypes.map(_toStringId),
            contains(endsWith(':collection#Equality')));
      });
    });

    test('with specified language versions from a PackageConfig', () async {
      var packageConfig = PackageConfig([
        Package('a', Uri.file('/a/'),
            packageUriRoot: Uri.file('/a/lib/'),
            languageVersion: LanguageVersion(2, 3))
      ]);
      var libExample = await resolveSource(r'''
        library example;

        extension _Foo on int {}
      ''', (resolver) => resolver.findLibraryNotNull2('example'),
          packageConfig: packageConfig, inputId: AssetId('a', 'invalid.dart'));
      var errors = await libExample.session
          .getErrors(libExample.firstFragment.source.fullName) as ErrorsResult;
      expect(
          errors.errors.map((e) => e.message),
          contains(contains(
              'This requires the \'extension-methods\' language feature to be '
              'enabled.')));
    });
  });

  group('should resolveAsset', () {
    test('asset:build_test/test/_files/example_lib.dart', () async {
      var asset = AssetId('build_test', 'test/_files/example_lib.dart');
      var libExample = await resolveAsset(
          asset, (resolver) => resolver.findLibraryNotNull2('example_lib'));
      expect(libExample.getClass2('Example'), isNotNull);
    });
  });

  group('error handling', () {
    test('getting the library for a part file', () async {
      var partAsset = AssetId('build_test', 'test/_files/example_part.dart');
      await resolveAsset(partAsset, (resolver) async {
        expect(
            () => resolver.libraryFor2(partAsset),
            throwsA(isA<NonLibraryAssetException>()
                .having((e) => e.assetId, 'assetId', partAsset)));
      });
    });
  });
}

String _toStringId(InterfaceType t) =>
    '${t.element3.enclosingElement2.uri.toString().split('/').first}#'
    '${t.element3.name3}';

extension on Resolver {
  Future<LibraryElement2> findLibraryNotNull2(String name) async {
    return (await findLibraryByName2(name))!;
  }
}
