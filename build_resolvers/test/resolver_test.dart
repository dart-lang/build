// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:isolate';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_resolvers/src/analysis_driver.dart';
import 'package:build_resolvers/src/resolver.dart';
import 'package:build_resolvers/src/sdk_summary.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  final entryPoint = AssetId('a', 'web/main.dart');

  group('Resolver', () {
    test('should handle initial files', () {
      return resolveSources({'a|web/main.dart': ' main() {}'}, (
        resolver,
      ) async {
        var lib = await resolver.libraryFor2(entryPoint);
        expect(lib, isNotNull);
      }, resolvers: AnalyzerResolvers());
    });

    test('should follow imports', () {
      return resolveSources(
        {
          'a|web/main.dart': '''
              import 'a.dart';

              main() {
              } ''',
          'a|web/a.dart': '''
              library a;
              ''',
        },
        (resolver) async {
          var lib = await resolver.libraryFor2(entryPoint);
          expect(lib.firstFragment.libraryImports2.length, 2);
          var libA = lib
            ..firstFragment
                .libraryImports2
                .where((l) => l.importedLibrary2!.name3 == 'a')
                .single;
          expect(libA.getClass2('Foo'), isNull);
        },
        resolvers: AnalyzerResolvers(),
      );
    });

    test('should follow package imports', () {
      return resolveSources(
        {
          'a|web/main.dart': '''
              import 'package:b/b.dart';

              main() {
              } ''',
          'b|lib/b.dart': '''
              library b;
              ''',
        },
        (resolver) async {
          var lib = await resolver.libraryFor2(entryPoint);
          expect(lib.firstFragment.libraryImports2.length, 2);
          var libB = lib
            ..firstFragment
                .libraryImports2
                .where((l) => l.importedLibrary2!.name3 == 'b')
                .single;
          expect(libB.getClass2('Foo'), isNull);
        },
        resolvers: AnalyzerResolvers(),
      );
    });

    test('should still crawl transitively after a call to isLibrary', () {
      return resolveSources(
        {
          'a|web/main.dart': '''
              import 'package:b/b.dart';

              main() {
              } ''',
          'b|lib/b.dart': '''
              library b;
              ''',
        },
        (resolver) async {
          await resolver.isLibrary(entryPoint);
          var libs = await resolver.libraries2.toList();
          expect(
            libs,
            contains(predicate((LibraryElement2 l) => l.name3 == 'b')),
          );
        },
        resolvers: AnalyzerResolvers(),
      );
    });

    test(
        'calling isLibrary does not include that library in the libraries '
        'stream', () {
      return resolveSources(
        {
          'a|web/main.dart': '',
          'b|lib/b.dart': '''
              library b;
              ''',
        },
        (resolver) async {
          await resolver.isLibrary(AssetId('b', 'lib/b.dart'));
          await expectLater(
            resolver.libraries2,
            neverEmits(
              isA<LibraryElement2>().having((e) => e.name3, 'name', 'b'),
            ),
          );
        },
        resolvers: AnalyzerResolvers(),
      );
    });

    test(
      'should still crawl transitively after a call to compilationUnitFor',
      () {
        return resolveSources(
          {
            'a|web/main.dart': '''
              import 'package:b/b.dart';

              main() {
              } ''',
            'b|lib/b.dart': '''
              library b;
              ''',
          },
          (resolver) async {
            await resolver.compilationUnitFor(entryPoint);
            var libs = await resolver.libraries2.toList();
            expect(
              libs,
              contains(predicate((LibraryElement2 l) => l.name3 == 'b')),
            );
          },
          resolvers: AnalyzerResolvers(),
        );
      },
    );

    group('language versioning', () {
      test('gives a correct languageVersion based on comments', () async {
        await resolveSources(
          {'a|web/main.dart': '// @dart=3.1\n\nmain() {}'},
          (resolver) async {
            var lib = await resolver.libraryFor2(entryPoint);
            expect(lib.languageVersion.effective.major, 3);
            expect(lib.languageVersion.effective.minor, 1);
          },
          resolvers: AnalyzerResolvers(),
        );
      });

      test('defaults to the current isolate package config', () async {
        await resolveSources({'a|web/main.dart': 'main() {}'}, (
          resolver,
        ) async {
          var buildResolversId = AssetId(
            'build_resolvers',
            'lib/build_resolvers.dart',
          );
          var lib = await resolver.libraryFor2(buildResolversId);
          var currentPackageConfig = await loadPackageConfigUri(
            (await Isolate.packageConfig)!,
          );
          var expectedVersion =
              currentPackageConfig['build_resolvers']!.languageVersion!;
          expect(lib.languageVersion.effective.major, expectedVersion.major);
          expect(lib.languageVersion.effective.minor, expectedVersion.minor);
        }, resolvers: AnalyzerResolvers());
      });

      test('uses the overridden package config if provided', () async {
        // An arbitrary past version that could never be selected for this
        // package.
        var customVersion = LanguageVersion(2, 1);
        var customPackageConfig = PackageConfig([
          Package(
            'a',
            Uri.file('/fake/a/'),
            packageUriRoot: Uri.file('/fake/a/lib/'),
            languageVersion: customVersion,
          ),
        ]);
        await resolveSources(
          {'a|web/main.dart': 'main() {}'},
          (resolver) async {
            var lib = await resolver.libraryFor2(entryPoint);
            expect(lib.languageVersion.effective.major, customVersion.major);
            expect(lib.languageVersion.effective.minor, customVersion.minor);
          },
          resolvers: AnalyzerResolvers(null, null, customPackageConfig),
        );
      });

      test('gives the current language version if not provided', () async {
        var customPackageConfig = PackageConfig([
          Package(
            'a',
            Uri.file('/fake/a/'),
            packageUriRoot: Uri.file('/fake/a/lib/'),
            languageVersion: null,
          ),
        ]);
        await resolveSources(
          {'a|web/main.dart': 'main() {}'},
          (resolver) async {
            var lib = await resolver.libraryFor2(entryPoint);
            expect(
              lib.languageVersion.effective.major,
              sdkLanguageVersion.major,
            );
            expect(
              lib.languageVersion.effective.minor,
              sdkLanguageVersion.minor,
            );
          },
          resolvers: AnalyzerResolvers(null, null, customPackageConfig),
        );
      });

      test(
        'allows a version of analyzer compatibile with the current sdk',
        skip: _skipOnPreRelease,
        () async {
          var originalLevel = Logger.root.level;
          Logger.root.level = Level.WARNING;
          var listener = Logger.root.onRecord.listen((record) {
            fail('Got an unexpected warning during analysis:\n\n$record');
          });
          addTearDown(() {
            Logger.root.level = originalLevel;
            listener.cancel();
          });
          await resolveSources({'a|web/main.dart': 'main() {}'}, (
            resolver,
          ) async {
            await resolver.libraryFor2(entryPoint);
          }, resolvers: AnalyzerResolvers());
        },
      );
    });

    group('assets that aren\'t a transitive import of input', () {
      Future runWith(Future Function(Resolver) test) {
        return resolveSources(
          {
            'a|web/main.dart': '''
          main() {}
        ''',
            'a|lib/other.dart': '''
          library other;
        ''',
          },
          test,
          resolvers: AnalyzerResolvers(),
        );
      }

      final otherId = AssetId.parse('a|lib/other.dart');

      test('can be resolved', () {
        return runWith((resolver) async {
          final main = await resolver.libraryFor2(entryPoint);
          expect(main, isNotNull);

          final other = await resolver.libraryFor2(otherId);
          expect(other.name3, 'other');
        });
      });

      test('are included in library stream', () {
        return runWith((resolver) async {
          await expectLater(
            resolver.libraries2.map((l) => l.name3),
            neverEmits('other'),
          );

          await resolver.libraryFor2(otherId);

          await expectLater(
            resolver.libraries2.map((l) => l.name3),
            emitsThrough('other'),
          );
        });
      });

      test('can be found by name', () {
        return runWith((resolver) async {
          await resolver.libraryFor2(otherId);

          await expectLater(
            resolver.findLibraryByName2('other'),
            completion(isNotNull),
          );
        });
      });
    });

    test('handles missing files', () {
      return resolveSources(
        {
          'a|web/main.dart': '''
              import 'package:b/missing.dart';

              part 'missing.g.dart';

              main() {
              } ''',
        },
        (resolver) async {
          var lib = await resolver.libraryFor2(entryPoint);
          expect(lib.fragments.length, 1);
        },
        resolvers: AnalyzerResolvers(),
      );
    });

    test('handles discovering previously missing parts', () async {
      var resolvers = AnalyzerResolvers();
      await resolveSources(
        {
          'a|web/main.dart': '''
              part 'main.g.dart';

              class A implements B {}
              ''',
        },
        (resolver) async {
          var lib = await resolver.libraryFor2(entryPoint);
          var clazz = lib.getClass2('A');
          expect(clazz, isNotNull);
          expect(clazz!.interfaces, isEmpty);
        },
        resolvers: resolvers,
      );

      await resolveSources(
        {
          'a|web/main.dart': '''
              part 'main.g.dart';

              class A implements B {}
              ''',
          'a|web/main.g.dart': '''
              part of 'main.dart';
              class B {}
              ''',
        },
        (resolver) async {
          var lib = await resolver.libraryFor2(entryPoint);
          var clazz = lib.getClass2('A');
          expect(clazz, isNotNull);
          expect(clazz!.interfaces, hasLength(1));
          expect(clazz.interfaces.first.getDisplayString(), 'B');
        },
        resolvers: resolvers,
      );
    });

    test('handles removing deleted parts', () async {
      var resolvers = AnalyzerResolvers();
      await resolveSources(
        {
          'a|web/main.dart': '''
              part 'main.g.dart';

              class A implements B {}
              ''',
          'a|web/main.g.dart': '''
              part of 'main.dart';
              class B {}
              ''',
        },
        (resolver) async {
          var lib = await resolver.libraryFor2(entryPoint);
          var clazz = lib.getClass2('A');
          expect(clazz, isNotNull);
          expect(clazz!.interfaces, hasLength(1));
          expect(clazz.interfaces.first.getDisplayString(), 'B');
        },
        resolvers: resolvers,
      );

      // `resolveSources` actually completes prior to the build step being
      // done, which causes this `reset` call to fail. After a few microtasks
      // it succeeds though.
      var tries = 0;
      while (tries++ < 5) {
        await Future.value(null);
        try {
          resolvers.reset();
        } catch (_) {}
      }

      await resolveSources(
        {
          'a|web/main.dart': '''
              part 'main.g.dart';

              class A implements B {}
              ''',
        },
        (resolver) async {
          var lib = await resolver.libraryFor2(entryPoint);
          var clazz = lib.getClass2('A');
          expect(clazz, isNotNull);
          expect(clazz!.interfaces, isEmpty);
        },
        resolvers: resolvers,
      );
    });

    test('should list all libraries', () {
      return resolveSources(
        {
          'a|web/main.dart': '''
              library a.main;
              import 'package:a/a.dart';
              import 'package:a/b.dart';
              export 'package:a/d.dart';
              ''',
          'a|lib/a.dart': 'library a.a;\n import "package:a/c.dart";',
          'a|lib/b.dart': 'library a.b;\n import "c.dart";',
          'a|lib/c.dart': 'library a.c;',
          'a|lib/d.dart': 'library a.d;',
        },
        (resolver) async {
          var libs =
              await resolver.libraries2.where((l) => !l.isInSdk).toList();
          expect(
            libs.map((l) => l.name3),
            unorderedEquals(['a.main', 'a.a', 'a.b', 'a.c', 'a.d']),
          );
        },
        resolvers: AnalyzerResolvers(),
      );
    });

    test('should resolve types and library uris', () {
      return resolveSources(
        {
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
        },
        (resolver) async {
          var a = await resolver.findLibraryByName2('a.a');
          expect(a, isNotNull);

          var main = await resolver.findLibraryByName2('');
          expect(main, isNotNull);
        },
        resolvers: AnalyzerResolvers(),
      );
    });

    test('resolves constants transitively', () {
      return resolveSources(
        {
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
        },
        (resolver) async {
          var main = (await resolver.findLibraryByName2('web.main'))!;
          var meta = main.getClass2('Foo')!.supertype!.element.metadata[0];
          expect(meta, isNotNull);
          expect(meta.computeConstantValue()?.toIntValue(), 0);
        },
        resolvers: AnalyzerResolvers(),
      );
    });

    test('handles circular imports', () {
      return resolveSources(
        {
          'a|web/main.dart': '''
                library main;
                import 'package:a/a.dart'; ''',
          'a|lib/a.dart': '''
                library a;
                import 'package:a/b.dart'; ''',
          'a|lib/b.dart': '''
                library b;
                import 'package:a/a.dart'; ''',
        },
        (resolver) async {
          var libs = await resolver.libraries2.map((lib) => lib.name3).toList();
          expect(libs.contains('a'), isTrue);
          expect(libs.contains('b'), isTrue);
        },
        resolvers: AnalyzerResolvers(),
      );
    });

    test('assetIdForElement', () {
      return resolveSources(
        {
          'a|lib/a.dart': '''
              import 'b.dart';

              main() {
                SomeClass();
              } ''',
          'a|lib/b.dart': '''
            class SomeClass {}
              ''',
        },
        (resolver) async {
          var entry = await resolver.libraryFor2(AssetId('a', 'lib/a.dart'));
          var classDefinition = entry.firstFragment.libraryImports2
              .map((l) => l.importedLibrary2!.getClass2('SomeClass'))
              .singleWhere((c) => c != null)!;
          expect(
            await resolver.assetIdForElement2(classDefinition),
            AssetId('a', 'lib/b.dart'),
          );
        },
        resolvers: AnalyzerResolvers(),
      );
    });

    test('assetIdForElement throws for ambiguous elements', () {
      return resolveSources(
        {
          'a|lib/a.dart': '''
              import 'b.dart';
              import 'c.dart';

              @SomeClass()
              main() {}
              ''',
          'a|lib/b.dart': '''
            class SomeClass {}
              ''',
          'a|lib/c.dart': '''
            class SomeClass {}
              ''',
        },
        (resolver) async {
          var entry = await resolver.libraryFor2(AssetId('a', 'lib/a.dart'));
          final element = entry.topLevelFunctions
              .firstWhere((e) => e.name3 == 'main')
              .metadata2
              .annotations
              .single;
          await expectLater(
            () => resolver.assetIdForElement2(element.element2!),
            throwsA(isA<UnresolvableAssetException>()),
          );
        },
        resolvers: AnalyzerResolvers(),
      );
    });

    test('Respects withEnabledExperiments', skip: _skipOnPreRelease, () async {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen(print);
      await withEnabledExperiments(
        () => resolveSources(
          {
            'a|web/main.dart': '''
// @dart=${sdkLanguageVersion.major}.${sdkLanguageVersion.minor}
int? get x => 1;
                ''',
          },
          (resolver) async {
            var lib = await resolver.libraryFor2(entryPoint);
            expect(
              lib.languageVersion.effective.major,
              sdkLanguageVersion.major,
            );
            expect(
              lib.languageVersion.effective.minor,
              sdkLanguageVersion.minor,
            );
            var errors =
                await lib.session.getErrors('/a/web/main.dart') as ErrorsResult;
            expect(errors.errors, isEmpty);
          },
          resolvers: AnalyzerResolvers(),
        ),
        ['non-nullable'],
      );
    });

    test(
      'can get a new analysis session after resolving additional assets',
      () async {
        var resolvers = AnalyzerResolvers();
        await resolveSources({'a|web/main.dart': '', 'a|web/other.dart': ''}, (
          resolver,
        ) async {
          var lib = await resolver.libraryFor2(entryPoint);
          expect(
            await resolver.isLibrary(AssetId('a', 'web/other.dart')),
            true,
          );
          var newLib = await resolver.libraryFor2(
            await resolver.assetIdForElement2(lib),
          );
          expect(
            await newLib.session.getResolvedLibraryByElement2(newLib),
            isA<ResolvedLibraryResult>(),
          );
        }, resolvers: resolvers);
      },
    );

    group('syntax errors', () {
      test('are reported', () {
        return resolveSources(
          {
            'a|errors.dart': '''
             library a_library;

             void withSyntaxErrors() {
               String x = ;
             }
          ''',
          },
          (resolver) async {
            await expectLater(
              resolver.libraryFor2(AssetId.parse('a|errors.dart')),
              throwsA(isA<SyntaxErrorInAssetException>()),
            );
            await expectLater(
              resolver.compilationUnitFor(AssetId.parse('a|errors.dart')),
              throwsA(isA<SyntaxErrorInAssetException>()),
            );
          },
        );
      });

      test('are reported for part files with errors', () {
        return resolveSources(
          {
            'a|lib.dart': '''
            library a_library;
            part 'errors.dart';
            part 'does_not_exist.dart';
          ''',
            'a|errors.dart': '''
             part of 'lib.dart';

             void withSyntaxErrors() {
               String x = ;
             }
          ''',
          },
          (resolver) async {
            await expectLater(
              resolver.libraryFor2(AssetId.parse('a|lib.dart')),
              throwsA(
                isA<SyntaxErrorInAssetException>().having(
                  (e) => e.syntaxErrors,
                  'syntaxErrors',
                  hasLength(1),
                ),
              ),
            );
            await expectLater(
              resolver.compilationUnitFor(AssetId.parse('a|errors.dart')),
              throwsA(
                isA<SyntaxErrorInAssetException>().having(
                  (e) => e.syntaxErrors,
                  'syntaxErrors',
                  hasLength(1),
                ),
              ),
            );
          },
        );
      });

      test('are not reported when disabled', () {
        return resolveSources(
          {
            'a|errors.dart': '''
             library a_library;

             void withSyntaxErrors() {
               String x = ;
             }
          ''',
          },
          (resolver) async {
            await expectLater(
              resolver.libraryFor2(
                AssetId.parse('a|errors.dart'),
                allowSyntaxErrors: true,
              ),
              completion(isNotNull),
            );
            await expectLater(
              resolver.compilationUnitFor(
                AssetId.parse('a|errors.dart'),
                allowSyntaxErrors: true,
              ),
              completion(isNotNull),
            );
          },
        );
      });

      test('are truncated if necessary', () {
        return resolveSources(
          {
            'a|errors.dart': '''
             library a_library;

             void withSyntaxErrors() {
               String x = ;
               String x = ;
               String x = ;
               String x = ;
               String x = ;
             }
          ''',
          },
          (resolver) async {
            var expectation = throwsA(
              isA<SyntaxErrorInAssetException>().having(
                (e) => e.toString(),
                'toString()',
                contains(RegExp(r'And \d more')),
              ),
            );
            await expectLater(
              resolver.libraryFor2(AssetId.parse('a|errors.dart')),
              expectation,
            );
            await expectLater(
              resolver.compilationUnitFor(AssetId.parse('a|errors.dart')),
              expectation,
            );
          },
        );
      });

      test('do not report semantic errors', () {
        return resolveSources(
          {
            'a|errors.dart': '''
             library a_library;

             void withSemanticErrors() {
               String x = withSemanticErrors();
               String x = null;
             }
          ''',
          },
          (resolver) async {
            await expectLater(
              resolver.libraryFor2(AssetId.parse('a|errors.dart')),
              completion(isNotNull),
            );
            await expectLater(
              resolver.compilationUnitFor(AssetId.parse('a|errors.dart')),
              completion(isNotNull),
            );
          },
        );
      });
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
        ''',
      },
      (resolver) async {
        final assetId = AssetId.parse('a|lib/b.dart');
        await expectLater(
          () => resolver.libraryFor2(assetId),
          throwsA(
            const TypeMatcher<NonLibraryAssetException>().having(
              (e) => e.assetId,
              'assetId',
              equals(assetId),
            ),
          ),
        );
      },
    );
  });

  test('Can resolve sdk libraries that are not imported', () async {
    await resolveSources({'a|lib/a.dart': ''}, (resolver) async {
      var convert = await resolver.findLibraryByName2('dart.convert');
      expect(convert, isNotNull);
      expect(convert!.getClass2('Codec'), isNotNull);
      var allLibraries = await resolver.libraries2.toList();
      expect(
        allLibraries.map((e) => e.uri.toString()),
        containsAll([
          'dart:async',
          'dart:collection',
          'dart:convert',
          'dart:core',
          'dart:math',
          'dart:typed_data',
          'dart:io',
          'dart:html',
          if (isFlutter) 'dart:ui',
        ]),
      );

      // Only public libraries should be reported
      expect(
        allLibraries,
        everyElement(
          isA<LibraryElement>().having(
            (e) => e.isPrivate,
            'isPrivate',
            isFalse,
          ),
        ),
      );
    }, resolvers: AnalyzerResolvers());
  });

  test('can resolve sdk libraries without seeing anything else', () async {
    await resolveSources({'a|lib/not_dart.txt': ''}, (resolver) async {
      var allLibraries = await resolver.libraries2.toList();

      expect(
        allLibraries.map((e) => e.uri.toString()),
        containsAll(['dart:io', 'dart:core', 'dart:html']),
      );
      expect(
        allLibraries,
        everyElement(
          isA<LibraryElement2>().having((e) => e.isInSdk, 'isInSdk', isTrue),
        ),
      );
    }, resolvers: AnalyzerResolvers());
  });

  test('sdk libraries can still be resolved after seeing new assets', () async {
    final resolvers = AnalyzerResolvers();
    final builder = TestBuilder(
      buildExtensions: {
        '.dart': ['.txt'],
      },
      build: (buildStep, buildExtensions) async {
        await buildStep.inputLibrary2;

        final allLibraries = await buildStep.resolver.libraries2.toList();
        expect(
          allLibraries.map((e) => e.uri.toString()),
          containsAll(['dart:io', 'dart:core', 'dart:html']),
        );
      },
    );

    final writer = InMemoryAssetWriter();
    final reader = InMemoryAssetReader.shareAssetCache(writer.assets);

    writer.assets[makeAssetId('a|lib/a.dart')] = utf8.encode('');
    await runBuilder(
      builder,
      [makeAssetId('a|lib/a.dart')],
      reader,
      writer,
      resolvers,
    );

    writer.assets[makeAssetId('a|lib/b.dart')] = utf8.encode('');
    await runBuilder(
      builder,
      [makeAssetId('a|lib/b.dart')],
      reader,
      writer,
      resolvers,
    );
  });

  group('The ${isFlutter ? 'flutter' : 'dart'} sdk', () {
    test('can${isFlutter ? '' : ' not'} resolve types from dart:ui', () async {
      return resolveSources(
        {
          'a|lib/a.dart': '''
              import 'dart:ui';

              class MyClass {
                final Color color;

                MyClass(this.color);
              } ''',
        },
        (resolver) async {
          var entry = await resolver.libraryFor2(AssetId('a', 'lib/a.dart'));
          var classDefinition = entry.getClass2('MyClass')!;
          var color = classDefinition.getField2('color')!;

          if (isFlutter) {
            expect(color.type.element3!.name3, equals('Color'));
            expect(color.type.element3!.library2!.name3, equals('dart.ui'));
            expect(
              color.type.element3!.library2!.uri.toString(),
              equals('dart:ui'),
            );
          } else {
            expect(color.type, isA<InvalidType>());
          }
        },
        resolvers: AnalyzerResolvers(),
      );
    });
  });

  test('generated part files are not considered libraries', () async {
    var writer = InMemoryAssetWriter();
    var reader = InMemoryAssetReader.shareAssetCache(writer.assets);
    var input = AssetId('a', 'lib/input.dart');
    writer.assets[input] = utf8.encode("part 'input.a.dart';");

    var builder = TestBuilder(
      buildExtensions: {
        '.dart': ['.a.dart'],
      },
      build: (buildStep, buildExtensions) async {
        var isLibrary = await buildStep.resolver.isLibrary(buildStep.inputId);
        if (buildStep.inputId == input) {
          await buildStep.writeAsString(
            buildStep.inputId.changeExtension(buildExtensions['.dart']!.first),
            "part of 'input.dart';",
          );
          expect(isLibrary, true);
        } else {
          expect(
            isLibrary,
            false,
            reason: '${buildStep.inputId} should not be considered a library',
          );
        }
      },
    );
    var resolvers = AnalyzerResolvers();
    await runBuilder(builder, [input], reader, writer, resolvers);

    await runBuilder(
      builder,
      [input.changeExtension('.a.dart')],
      reader,
      writer,
      resolvers,
    );
  });

  test('missing files are not considered libraries', () async {
    var writer = InMemoryAssetWriter();
    var reader = InMemoryAssetReader.shareAssetCache(writer.assets);
    var input = AssetId('a', 'lib/input.dart');
    writer.assets[input] = utf8.encode('void doStuff() {}');

    var builder = TestBuilder(
      buildExtensions: {
        '.dart': ['.a.dart'],
      },
      build: expectAsync2((buildStep, _) async {
        expect(
          await buildStep.resolver.isLibrary(
            buildStep.inputId.changeExtension('doesnotexist.dart'),
          ),
          false,
        );
      }),
    );
    var resolvers = AnalyzerResolvers();
    await runBuilder(builder, [input], reader, writer, resolvers);
  });

  test(
    'assets with extensions other than `.dart` are not considered libraries',
    () async {
      var writer = InMemoryAssetWriter();
      var reader = InMemoryAssetReader.shareAssetCache(writer.assets);
      var input = AssetId('a', 'lib/input.dart');
      writer.assets[input] = utf8.encode('void doStuff() {}');

      var otherFile = AssetId('a', 'lib/input.notdart');
      writer.assets[otherFile] = utf8.encode('Not a Dart file');

      var builder = TestBuilder(
        buildExtensions: {
          '.dart': ['.a.dart'],
        },
        build: expectAsync2((buildStep, _) async {
          var other = buildStep.inputId.changeExtension('.notdart');
          expect(await buildStep.canRead(other), true);
          expect(await buildStep.resolver.isLibrary(other), false);
        }),
      );
      var resolvers = AnalyzerResolvers();
      await runBuilder(builder, [input], reader, writer, resolvers);
    },
  );

  group('compilationUnitFor', () {
    test('can parse a given input', () {
      return resolveSources({'a|web/main.dart': ' main() {}'}, (
        resolver,
      ) async {
        var unit = await resolver.compilationUnitFor(entryPoint);
        expect(unit, isNotNull);
        expect(unit.declarations.length, 1);
        expect(
          unit.declarations.first,
          isA<FunctionDeclaration>().having(
            (d) => d.name.lexeme,
            'main',
            'main',
          ),
        );
      }, resolvers: AnalyzerResolvers());
    });
  });

  group('astNodeFor', () {
    test('can return an unresolved ast', () {
      return resolveSources({'a|web/main.dart': ' main() {}'}, (
        resolver,
      ) async {
        var lib = await resolver.libraryFor2(entryPoint);
        var unit = await resolver
            .astNodeFor2(lib.topLevelFunctions.first.firstFragment);
        expect(unit, isA<FunctionDeclaration>());
        expect(unit!.toSource(), 'main() {}');
        expect((unit as FunctionDeclaration).declaredFragment, isNull);
      }, resolvers: AnalyzerResolvers());
    });

    test('can return an resolved ast', () {
      return resolveSources({'a|web/main.dart': 'main() {}'}, (resolver) async {
        var lib = await resolver.libraryFor2(entryPoint);
        var unit = await resolver.astNodeFor2(
          lib.topLevelFunctions.first.firstFragment,
          resolve: true,
        );
        expect(
          unit,
          isA<FunctionDeclaration>()
              .having((fd) => fd.toSource(), 'toSource()', 'main() {}')
              .having(
                  (fd) => fd.declaredFragment, 'declaredFragment', isNotNull),
        );
      }, resolvers: AnalyzerResolvers());
    });

    test('can return a resolved compilation unit', () {
      return resolveSources({'a|web/main.dart': 'main() {}'}, (resolver) async {
        var lib = await resolver.libraryFor2(entryPoint);
        var unit = await resolver.astNodeFor2(
          lib.firstFragment,
          resolve: true,
        );
        expect(
          unit,
          isA<CompilationUnit>().having(
            (unit) => unit.declarations,
            'declarations',
            hasLength(1),
          ),
        );
        expect(
          (unit as CompilationUnit).declarations.single,
          isA<FunctionDeclaration>()
              .having((fd) => fd.toSource(), 'toSource()', 'main() {}')
              .having((fd) => fd.declaredElement, 'declaredElement', isNotNull),
        );
      });
    });
  });
}

final _skipOnPreRelease =
    Version.parse(Platform.version.split(' ').first).isPreRelease
        ? 'Skipped on prerelease sdks'
        : null;
