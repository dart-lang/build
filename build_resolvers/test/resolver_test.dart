// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_resolvers/src/resolver.dart';

void main() {
  final entryPoint = AssetId('a', 'web/main.dart');

  group('Resolver', () {
    test('should handle initial files', () {
      return resolveSources({
        'a|web/main.dart': ' main() {}',
      }, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        expect(lib, isNotNull);
      }, resolvers: AnalyzerResolvers());
    });

    test('should follow imports', () {
      return resolveSources({
        'a|web/main.dart': '''
              import 'a.dart';

              main() {
              } ''',
        'a|web/a.dart': '''
              library a;
              ''',
      }, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        expect(lib.importedLibraries.length, 2);
        var libA = lib.importedLibraries.where((l) => l.name == 'a').single;
        expect(libA.getType('Foo'), isNull);
      }, resolvers: AnalyzerResolvers());
    });

    test('should follow package imports', () {
      return resolveSources({
        'a|web/main.dart': '''
              import 'package:b/b.dart';

              main() {
              } ''',
        'b|lib/b.dart': '''
              library b;
              ''',
      }, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        expect(lib.importedLibraries.length, 2);
        var libB = lib.importedLibraries.where((l) => l.name == 'b').single;
        expect(libB.getType('Foo'), isNull);
      }, resolvers: AnalyzerResolvers());
    });

    group('assets that aren\'t a transitive import of input', () {
      Future _runWith(Future Function(Resolver) test) {
        return resolveSources({
          'a|web/main.dart': '''
          main() {}
        ''',
          'a|lib/other.dart': '''
          library other;
        '''
        }, test);
      }

      test('can be resolved', () {
        return _runWith((resolver) async {
          final main = await resolver.libraryFor(entryPoint);
          expect(main, isNotNull);

          final other =
              await resolver.libraryFor(AssetId.parse('a|lib/other.dart'));
          expect(other.name, 'other');
        });
      });

      test('are included in library stream', () {
        return _runWith((resolver) async {
          expect(resolver.libraries.map((l) => l.name), neverEmits('other'));

          await resolver.libraryFor(entryPoint);

          expect(resolver.libraries.map((l) => l.name), emits('other'));
        });
      });

      test('can be found by name', () {
        return _runWith((resolver) async {
          await resolver.libraryFor(entryPoint);

          expect(resolver.findLibraryByName('other'), completion(isNotNull));
        });
      });
    });

    test('handles missing files', () {
      return resolveSources({
        'a|web/main.dart': '''
              import 'package:b/missing.dart';

              part 'missing.g.dart';

              main() {
              } ''',
      }, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        expect(lib.imports.length, 2);
        expect(lib.parts.length, 1);
      }, resolvers: AnalyzerResolvers());
    });

    test('can read missing files that appear later', () async {
      var resolvers = AnalyzerResolvers();
      var sources = {
        'a|web/main.dart': "part 'a.g.dart';",
      };
      await resolveSources(sources, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        expect(lib.getType('A'), isNull);
      }, resolvers: resolvers);

      sources['a|web/a.g.dart'] = 'class A {}';

      await resolveSources(sources, (resolver) async {
        var lib = await resolver.libraryFor(entryPoint);
        expect(lib.getType('A'), isNotNull);
      }, resolvers: resolvers);
    }, skip: 'https://github.com/dart-lang/build/issues/2389');

    test('should list all libraries', () {
      return resolveSources({
        'a|web/main.dart': '''
              library a.main;
              import 'package:a/a.dart';
              import 'package:a/b.dart';
              export 'package:a/d.dart';
              ''',
        'a|lib/a.dart': 'library a.a;\n import "package:a/c.dart";',
        'a|lib/b.dart': 'library a.b;\n import "c.dart";',
        'a|lib/c.dart': 'library a.c;',
        'a|lib/d.dart': 'library a.d;'
      }, (resolver) async {
        var libs = await resolver.libraries.where((l) => !l.isInSdk).toList();
        expect(
            libs.map((l) => l.name),
            unorderedEquals([
              'a.main',
              'a.a',
              'a.b',
              'a.c',
              'a.d',
            ]));
      }, resolvers: AnalyzerResolvers());
    });

    test('should resolve types and library uris', () {
      return resolveSources({
        'a|web/main.dart': '''
              // dart and dart-ext uris should be ignored
              import 'dart:core';
              import 'dart-ext:some-ext';

              // package: and relative uris should be available
              import 'package:a/a.dart';
              import 'package:a/b.dart';
              import 'sub_dir/d.dart';
              class Foo {}
              ''',
        'a|lib/a.dart': 'library a.a;\n import "package:a/c.dart";',
        'a|lib/b.dart': 'library a.b;\n import "c.dart";',
        'a|lib/c.dart': '''
                library a.c;
                class Bar {}
                ''',
        'a|web/sub_dir/d.dart': '''
                library a.web.sub_dir.d;
                class Baz{}
                ''',
      }, (resolver) async {
        var a = await resolver.findLibraryByName('a.a');
        expect(a, isNotNull);

        var main = await resolver.findLibraryByName('');
        expect(main, isNotNull);
      }, resolvers: AnalyzerResolvers());
    });

    test('does not resolve constants transitively', () {
      return resolveSources({
        'a|web/main.dart': '''
              library web.main;

              import 'package:a/dont_resolve.dart';
              export 'package:a/dont_resolve.dart';

              class Foo extends Bar {}
              ''',
        'a|lib/dont_resolve.dart': '''
              library a.dont_resolve;

              const int annotation = 0;
              @annotation
              class Bar {}''',
      }, (resolver) async {
        var main = await resolver.findLibraryByName('web.main');
        var meta = main.getType('Foo').supertype.element.metadata[0];
        expect(meta, isNotNull);
        expect(meta.constantValue, isNull);
      }, resolvers: AnalyzerResolvers());
    });

    test('handles circular imports', () {
      return resolveSources({
        'a|web/main.dart': '''
                library main;
                import 'package:a/a.dart'; ''',
        'a|lib/a.dart': '''
                library a;
                import 'package:a/b.dart'; ''',
        'a|lib/b.dart': '''
                library b;
                import 'package:a/a.dart'; ''',
      }, (resolver) async {
        var libs = await resolver.libraries.map((lib) => lib.name).toList();
        expect(libs.contains('a'), isTrue);
        expect(libs.contains('b'), isTrue);
      }, resolvers: AnalyzerResolvers());
    });

    test('assetIdForElement', () {
      return resolveSources({
        'a|lib/a.dart': '''
              import 'b.dart';

              main() {
                SomeClass();
              } ''',
        'a|lib/b.dart': '''
            class SomeClass {}
              ''',
      }, (resolver) async {
        var entry = await resolver.libraryFor(AssetId('a', 'lib/a.dart'));
        var classDefinition = entry.importedLibraries
            .map((l) => l.getType('SomeClass'))
            .singleWhere((c) => c != null);
        expect(await resolver.assetIdForElement(classDefinition),
            AssetId('a', 'lib/b.dart'));
      }, resolvers: AnalyzerResolvers());
    });
  });

  test('throws when reading a part-of file', () {
    return resolveSources(
      {
        'a|lib/a.dart': '''
          part 'b.dart';
        ''',
        'a|lib/b.dart': '''
          part of 'a.dart';
        '''
      },
      (resolver) async {
        final assetId = AssetId.parse('a|lib/b.dart');
        await expectLater(
          () => resolver.libraryFor(assetId),
          throwsA(const TypeMatcher<NonLibraryAssetException>()
              .having((e) => e.assetId, 'assetId', equals(assetId))),
        );
      },
    );
  });

  group('The ${isFlutter ? 'flutter' : 'dart'} sdk', () {
    test('can${isFlutter ? '' : ' not'} resolve types from dart:ui', () async {
      return resolveSources({
        'a|lib/a.dart': '''
              import 'dart:ui';

              class MyClass {
                final Color color;

                MyClass(this.color);
              } ''',
      }, (resolver) async {
        var entry = await resolver.libraryFor(AssetId('a', 'lib/a.dart'));
        var classDefinition = entry.getType('MyClass');
        var color = classDefinition.getField('color');

        if (isFlutter) {
          expect(color.type.element.name, equals('Color'));
          expect(color.type.element.library.name, equals('dart.ui'));
          expect(
              color.type.element.library.definingCompilationUnit.source.uri
                  .toString(),
              equals('dart:ui'));
        } else {
          expect(color.type.element.name, equals('dynamic'));
        }
      }, resolvers: AnalyzerResolvers());
    });
  });
}
