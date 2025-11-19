// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Platform;
import 'dart:isolate';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_runner/src/build/resolver/analysis_driver.dart';
import 'package:build_runner/src/build/resolver/analysis_driver_model.dart';
import 'package:build_runner/src/build/resolver/resolver.dart';
import 'package:build_runner/src/build/resolver/sdk_summary.dart';
import 'package:build_runner/src/build/run_builder.dart';
import 'package:build_runner/src/build/single_step_reader_writer.dart';
import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../../common/common.dart';

void main() {
  for (final resolversFactory in [
    AnalysisDriverModelFactory(),
    SharedAnalysisDriverModelFactory(),
  ]) {
    group('$resolversFactory', () {
      runTests(resolversFactory);
    });
  }
}

void runTests(ResolversFactory resolversFactory) {
  final entryPoint = AssetId('a', 'web/main.dart');
  Resolvers createResolvers({PackageConfig? packageConfig}) =>
      resolversFactory.create(packageConfig: packageConfig);
  test('should handle initial files', () {
    return resolveSources({'a|web/main.dart': ' main() {}'}, (resolver) async {
      final lib = await resolver.libraryFor(entryPoint);
      expect(lib, isNotNull);
    }, resolvers: createResolvers());
  });

  test('provides access to source', () {
    return resolveSources({'a|web/main.dart': ' main() {}'}, (resolver) async {
      final lib = await resolver.libraryFor(entryPoint);
      expect(lib.firstFragment.source.contents.data, ' main() {}');
    }, resolvers: createResolvers());
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
        final lib = await resolver.libraryFor(entryPoint);
        expect(lib.firstFragment.libraryImports.length, 2);
        final libA =
            lib
              ..firstFragment.libraryImports
                  .where((l) => l.importedLibrary!.name == 'a')
                  .single;
        expect(libA.getClass('Foo'), isNull);
      },
      resolvers: createResolvers(),
    );
  });

  test('does not stack overflow on long import chain', () {
    return resolveSources(
      {
        'a|web/main.dart': '''
              import 'lib0.dart';

              main() {
              } ''',
        for (var i = 0; i != 750; ++i)
          'a|web/lib$i.dart': i == 749 ? '' : 'import "lib${i + 1}.dart";',
      },
      (resolver) async {
        await resolver.libraryFor(entryPoint);
      },
      resolvers: createResolvers(),
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
        final lib = await resolver.libraryFor(entryPoint);
        expect(lib.firstFragment.libraryImports.length, 2);
        final libB =
            lib
              ..firstFragment.libraryImports
                  .where((l) => l.importedLibrary!.name == 'b')
                  .single;
        expect(libB.getClass('Foo'), isNull);
      },
      resolvers: createResolvers(),
    );
  });

  test('informs buildStep that transitive imports were read', () {
    return resolveSources(
      {
        'a|web/main.dart': '''
              import 'a.dart';
              main() {
              } ''',
        'a|web/a.dart': '''
              library a;
              import 'b.dart';
              ''',
        'a|web/b.dart': '''
              library b;
              ''',
      },
      (resolver) async {
        await resolver.libraryFor(entryPoint);
      },
      assetReaderChecks: (reader) {
        expect(reader.testing.resolverEntrypointsTracked, {
          AssetId('a', 'web/main.dart'),
        });
      },
      resolvers: createResolvers(),
    );
  });

  test('updates following a change to source', () async {
    final resolvers = createResolvers();
    await resolveSources(
      {
        'a|web/main.dart': '''
              class A {}
              ''',
      },
      (resolver) async {
        final lib = await resolver.libraryFor(entryPoint);
        expect(lib.getClass('A'), isNotNull);
        expect(lib.getClass('B'), isNull);
      },
      resolvers: resolvers,
    );

    // Only allow changes to source between builds.
    await _resetResolvers(resolvers);

    await resolveSources(
      {
        'a|web/main.dart': '''
              class B {}
              ''',
      },
      (resolver) async {
        final lib = await resolver.libraryFor(entryPoint);
        expect(lib.getClass('A'), isNull);
        expect(lib.getClass('B'), isNotNull);
      },
      resolvers: resolvers,
    );
  });

  test('updates following a change to import graph', () async {
    final resolvers = createResolvers();
    await resolveSources(
      {
        'a|web/main.dart': '''
              part 'main.part1.dart';
              ''',
        'a|web/main.part1.dart': '''
              part of 'main.dart';
              class A {}
              ''',
      },
      (resolver) async {
        final lib = await resolver.libraryFor(entryPoint);
        expect(lib.getClass('A'), isNotNull);
        expect(lib.getClass('B'), isNull);
      },
      resolvers: resolvers,
    );

    // Only allow changes to source between builds.
    await _resetResolvers(resolvers);

    await resolveSources(
      {
        'a|web/main.dart': '''
              part 'main.part1.dart';
              ''',
        'a|web/main.part1.dart': '''
              part of 'main.dart';
              class B {}
              ''',
      },
      (resolver) async {
        final lib = await resolver.libraryFor(entryPoint);
        expect(lib.getClass('A'), isNull);
        expect(lib.getClass('B'), isNotNull);
      },
      resolvers: resolvers,
    );
  });

  test('updates graph when a missing file appears during build', () async {
    final resolvers = createResolvers();
    final sources = {
      'a|web/main.dart': '''
              import 'b.dart';

              class A implements C {}
              ''',
      'a|web/b.dart': '''
              export 'c.dart';
              ''',
      'a|web/c.dart': '''
              class C {}
              ''',
    };
    final sourcesWithoutB = Map.of(sources)..remove('a|web/b.dart');
    await resolveSources(sourcesWithoutB, (resolver) async {
      final lib = await resolver.libraryFor(entryPoint);
      final clazz = lib.getClass('A');
      expect(clazz, isNotNull);
      expect(clazz!.interfaces, isEmpty);
    }, resolvers: resolvers);

    await resolveSources(sources, (resolver) async {
      final lib = await resolver.libraryFor(entryPoint);
      final clazz = lib.getClass('A');
      expect(clazz, isNotNull);
      expect(clazz!.interfaces, hasLength(1));
      expect(clazz.interfaces.first.getDisplayString(), 'C');
    }, resolvers: resolvers);
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
        final libs = await resolver.libraries.toList();
        expect(libs, contains(predicate((LibraryElement l) => l.name == 'b')));
      },
      resolvers: createResolvers(),
    );
  });

  test('calling isLibrary does not include that library in the libraries '
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
          resolver.libraries,
          neverEmits(isA<LibraryElement>().having((e) => e.name, 'name', 'b')),
        );
      },
      resolvers: createResolvers(),
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
          final libs = await resolver.libraries.toList();
          expect(
            libs,
            contains(predicate((LibraryElement l) => l.name == 'b')),
          );
        },
        resolvers: createResolvers(),
      );
    },
  );

  group('language versioning', () {
    test('gives a correct languageVersion based on comments', () async {
      await resolveSources(
        {'a|web/main.dart': '// @dart=3.1\n\nmain() {}'},
        (resolver) async {
          final lib = await resolver.libraryFor(entryPoint);
          expect(lib.languageVersion.effective.major, 3);
          expect(lib.languageVersion.effective.minor, 1);
        },
        resolvers: createResolvers(),
      );
    });

    test('defaults to the current isolate package config', () async {
      await resolveSources(
        {'a|web/main.dart': 'main() {}'},
        nonInputsToReadFromFilesystem: {
          AssetId('build_runner', 'lib/src/build_runner.dart'),
        },
        (resolver) async {
          final buildResolversId = AssetId(
            'build_runner',
            'lib/src/build_runner.dart',
          );
          final lib = await resolver.libraryFor(buildResolversId);
          final currentPackageConfig = await loadPackageConfigUri(
            (await Isolate.packageConfig)!,
          );
          final expectedVersion =
              currentPackageConfig['build_runner']!.languageVersion!;
          expect(lib.languageVersion.effective.major, expectedVersion.major);
          expect(lib.languageVersion.effective.minor, expectedVersion.minor);
        },
        resolvers: createResolvers(),
      );
    });

    test('uses the overridden package config if provided', () async {
      // An arbitrary past version that could never be selected for this
      // package.
      final customVersion = LanguageVersion(2, 1);
      final customPackageConfig = PackageConfig([
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
          final lib = await resolver.libraryFor(entryPoint);
          expect(lib.languageVersion.effective.major, customVersion.major);
          expect(lib.languageVersion.effective.minor, customVersion.minor);
        },
        resolvers: createResolvers(packageConfig: customPackageConfig),
      );
    });

    test('gives the current language version if not provided', () async {
      final customPackageConfig = PackageConfig([
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
          final lib = await resolver.libraryFor(entryPoint);
          expect(lib.languageVersion.effective.major, sdkLanguageVersion.major);
          expect(lib.languageVersion.effective.minor, sdkLanguageVersion.minor);
        },
        resolvers: createResolvers(packageConfig: customPackageConfig),
      );
    });

    test(
      'allows a version of analyzer compatibile with the current sdk',
      skip: _skipOnPreRelease,
      () async {
        final originalLevel = Logger.root.level;
        Logger.root.level = Level.WARNING;
        final listener = Logger.root.onRecord.listen((record) {
          fail('Got an unexpected warning during analysis:\n\n$record');
        });
        addTearDown(() {
          Logger.root.level = originalLevel;
          listener.cancel();
        });
        await resolveSources({'a|web/main.dart': 'main() {}'}, (
          resolver,
        ) async {
          await resolver.libraryFor(entryPoint);
        }, resolvers: createResolvers());
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
        resolvers: createResolvers(),
      );
    }

    final otherId = AssetId.parse('a|lib/other.dart');

    test('can be resolved', () {
      return runWith((resolver) async {
        final main = await resolver.libraryFor(entryPoint);
        expect(main, isNotNull);

        final other = await resolver.libraryFor(otherId);
        expect(other.name, 'other');
      });
    });

    test('are included in library stream', () {
      return runWith((resolver) async {
        await expectLater(
          resolver.libraries.map((l) => l.name),
          neverEmits('other'),
        );

        await resolver.libraryFor(otherId);

        await expectLater(
          resolver.libraries.map((l) => l.name),
          emitsThrough('other'),
        );
      });
    });

    test('can be found by name', () {
      return runWith((resolver) async {
        await resolver.libraryFor(otherId);

        await expectLater(
          resolver.findLibraryByName('other'),
          completion(isNotNull),
        );
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
          final lib = await resolver.libraryFor(entryPoint);
          expect(lib.fragments.length, 1);
        },
        resolvers: createResolvers(),
      );
    });

    test('handles discovering previously missing parts', () async {
      final resolvers = createResolvers();
      await resolveSources(
        {
          'a|web/main.dart': '''
              part 'main.g.dart';

              class A implements B {}
              ''',
        },
        (resolver) async {
          final lib = await resolver.libraryFor(entryPoint);
          final clazz = lib.getClass('A');
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
          final lib = await resolver.libraryFor(entryPoint);
          final clazz = lib.getClass('A');
          expect(clazz, isNotNull);
          expect(clazz!.interfaces, hasLength(1));
          expect(clazz.interfaces.first.getDisplayString(), 'B');
        },
        resolvers: resolvers,
      );
    });

    test('handles removing deleted parts', () async {
      final resolvers = createResolvers();
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
          final lib = await resolver.libraryFor(entryPoint);
          final clazz = lib.getClass('A');
          expect(clazz, isNotNull);
          expect(clazz!.interfaces, hasLength(1));
          expect(clazz.interfaces.first.getDisplayString(), 'B');
        },
        resolvers: resolvers,
      );

      await _resetResolvers(resolvers);

      await resolveSources(
        {
          'a|web/main.dart': '''
              part 'main.g.dart';

              class A implements B {}
              ''',
        },
        (resolver) async {
          final lib = await resolver.libraryFor(entryPoint);
          final clazz = lib.getClass('A');
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
          final libs =
              await resolver.libraries.where((l) => !l.isInSdk).toList();
          expect(
            libs.map((l) => l.name),
            unorderedEquals(['a.main', 'a.a', 'a.b', 'a.c', 'a.d']),
          );
        },
        resolvers: createResolvers(),
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
          final a = await resolver.findLibraryByName('a.a');
          expect(a, isNotNull);

          final main = await resolver.findLibraryByName('');
          expect(main, isNotNull);
        },
        resolvers: createResolvers(),
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
          final main = (await resolver.findLibraryByName('web.main'))!;
          final meta =
              main.getClass('Foo')!.supertype!.element.metadata.annotations[0];
          expect(meta, isNotNull);
          expect(meta.computeConstantValue()?.toIntValue(), 0);
        },
        resolvers: createResolvers(),
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
          final libs = await resolver.libraries.map((lib) => lib.name).toList();
          expect(libs.contains('a'), isTrue);
          expect(libs.contains('b'), isTrue);
        },
        resolvers: createResolvers(),
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
          final entry = await resolver.libraryFor(AssetId('a', 'lib/a.dart'));
          final classDefinition =
              entry.firstFragment.libraryImports
                  .map((l) => l.importedLibrary!.getClass('SomeClass'))
                  .singleWhere((c) => c != null)!;
          expect(
            await resolver.assetIdForElement(classDefinition),
            AssetId('a', 'lib/b.dart'),
          );
        },
        resolvers: createResolvers(),
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
          final entry = await resolver.libraryFor(AssetId('a', 'lib/a.dart'));
          final element =
              entry.topLevelFunctions
                  .firstWhere((e) => e.name == 'main')
                  .metadata
                  .annotations
                  .single
                  .element!;
          await expectLater(
            () => resolver.assetIdForElement(element),
            throwsA(isA<UnresolvableAssetException>()),
          );
        },
        resolvers: createResolvers(),
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
            final lib = await resolver.libraryFor(entryPoint);
            expect(
              lib.languageVersion.effective.major,
              sdkLanguageVersion.major,
            );
            expect(
              lib.languageVersion.effective.minor,
              sdkLanguageVersion.minor,
            );
            final errors =
                await lib.session.getErrors('/a/web/main.dart') as ErrorsResult;
            expect(errors.diagnostics, isEmpty);
          },
          resolvers: createResolvers(),
        ),
        ['non-nullable'],
      );
    });

    test(
      'can get a new analysis session after resolving additional assets',
      () async {
        final resolvers = createResolvers();
        await resolveSources({'a|web/main.dart': '', 'a|web/other.dart': ''}, (
          resolver,
        ) async {
          final lib = await resolver.libraryFor(entryPoint);
          expect(
            await resolver.isLibrary(AssetId('a', 'web/other.dart')),
            true,
          );
          final newLib = await resolver.libraryFor(
            await resolver.assetIdForElement(lib),
          );
          expect(
            await newLib.session.getResolvedLibraryByElement(newLib),
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
              resolver.libraryFor(AssetId.parse('a|errors.dart')),
              throwsA(isA<SyntaxErrorInAssetException>()),
            );
            await expectLater(
              resolver.compilationUnitFor(AssetId.parse('a|errors.dart')),
              throwsA(isA<SyntaxErrorInAssetException>()),
            );
          },
          resolvers: createResolvers(),
        );
      });

      test('are only reported if severe', () {
        return resolveSources(
          {
            'a|errors.dart': '''
            /// {@code }
            class A{}
          ''',
          },
          (resolver) async {
            await expectLater(
              resolver.libraryFor(AssetId.parse('a|errors.dart')),
              completion(isNotNull),
            );
            await expectLater(
              resolver.compilationUnitFor(AssetId.parse('a|errors.dart')),
              completion(isNotNull),
            );
          },
          resolvers: createResolvers(),
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
              resolver.libraryFor(AssetId.parse('a|lib.dart')),
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
          resolvers: createResolvers(),
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
              resolver.libraryFor(
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
          resolvers: createResolvers(),
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
            final expectation = throwsA(
              isA<SyntaxErrorInAssetException>().having(
                (e) => e.toString(),
                'toString()',
                contains(RegExp(r'And \d more')),
              ),
            );
            await expectLater(
              resolver.libraryFor(AssetId.parse('a|errors.dart')),
              expectation,
            );
            await expectLater(
              resolver.compilationUnitFor(AssetId.parse('a|errors.dart')),
              expectation,
            );
          },
          resolvers: createResolvers(),
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
              resolver.libraryFor(AssetId.parse('a|errors.dart')),
              completion(isNotNull),
            );
            await expectLater(
              resolver.compilationUnitFor(AssetId.parse('a|errors.dart')),
              completion(isNotNull),
            );
          },
          resolvers: createResolvers(),
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
          () => resolver.libraryFor(assetId),
          throwsA(
            const TypeMatcher<NonLibraryAssetException>().having(
              (e) => e.assetId,
              'assetId',
              equals(assetId),
            ),
          ),
        );
      },
      resolvers: createResolvers(),
    );
  });

  test('Can resolve sdk libraries that are not imported', () async {
    await resolveSources({'a|lib/a.dart': ''}, (resolver) async {
      final convert = await resolver.findLibraryByName('dart.convert');
      expect(convert, isNotNull);
      expect(convert!.getClass('Codec'), isNotNull);
      final allLibraries = await resolver.libraries.toList();
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
    }, resolvers: createResolvers());
  });

  test('can resolve sdk libraries without seeing anything else', () async {
    await resolveSources({'a|lib/not_dart.txt': ''}, (resolver) async {
      final allLibraries = await resolver.libraries.toList();

      expect(
        allLibraries.map((e) => e.uri.toString()),
        containsAll(['dart:io', 'dart:core', 'dart:html']),
      );
      expect(
        allLibraries,
        everyElement(
          isA<LibraryElement>().having((e) => e.isInSdk, 'isInSdk', isTrue),
        ),
      );
    }, resolvers: createResolvers());
  });

  test('sdk libraries can still be resolved after seeing new assets', () async {
    final resolvers = createResolvers();
    final builder = TestBuilder(
      buildExtensions: {
        '.dart': ['.txt'],
      },
      build: (buildStep, buildExtensions) async {
        await buildStep.inputLibrary;

        final allLibraries = await buildStep.resolver.libraries.toList();
        expect(
          allLibraries.map((e) => e.uri.toString()),
          containsAll(['dart:io', 'dart:core', 'dart:html']),
        );
      },
    );

    final readerWriter = InternalTestReaderWriter();

    readerWriter.testing.writeString(makeAssetId('a|lib/a.dart'), '');
    await runBuilder(
      builder,
      [makeAssetId('a|lib/a.dart')],
      SingleStepReaderWriter.fakeFor(readerWriter),
      resolvers,
    );

    readerWriter.testing.writeString(makeAssetId('a|lib/b.dart'), '');
    await runBuilder(
      builder,
      [makeAssetId('a|lib/b.dart')],
      SingleStepReaderWriter.fakeFor(readerWriter),
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
          final entry = await resolver.libraryFor(AssetId('a', 'lib/a.dart'));
          final classDefinition = entry.getClass('MyClass')!;
          final color = classDefinition.getField('color')!;

          if (isFlutter) {
            expect(color.type.element!.name, equals('Color'));
            expect(color.type.element!.library!.name, equals('dart.ui'));
            expect(
              color.type.element!.library!.uri.toString(),
              equals('dart:ui'),
            );
          } else {
            expect(color.type, isA<InvalidType>());
          }
        },
        resolvers: createResolvers(),
      );
    });
  });

  test('generated part files are not considered libraries', () async {
    final readerWriter = InternalTestReaderWriter();
    final input = AssetId('a', 'lib/input.dart');
    readerWriter.testing.writeString(input, "part 'input.a.dart';");

    final builder = TestBuilder(
      buildExtensions: {
        '.dart': ['.a.dart'],
      },
      build: (buildStep, buildExtensions) async {
        final isLibrary = await buildStep.resolver.isLibrary(buildStep.inputId);
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
    final resolvers = createResolvers();
    await runBuilder(
      builder,
      [input],
      SingleStepReaderWriter.fakeFor(readerWriter),
      resolvers,
    );

    await runBuilder(
      builder,
      [input.changeExtension('.a.dart')],
      SingleStepReaderWriter.fakeFor(readerWriter),
      resolvers,
    );
  });

  test('missing files are not considered libraries', () async {
    final readerWriter = InternalTestReaderWriter();
    final input = AssetId('a', 'lib/input.dart');
    readerWriter.testing.writeString(input, 'void doStuff() {}');

    final builder = TestBuilder(
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
    final resolvers = createResolvers();
    await runBuilder(
      builder,
      [input],
      SingleStepReaderWriter.fakeFor(readerWriter),
      resolvers,
    );
  });

  test(
    'assets with extensions other than `.dart` are not considered libraries',
    () async {
      final readerWriter = InternalTestReaderWriter();
      final input = AssetId('a', 'lib/input.dart');
      readerWriter.testing.writeString(input, 'void doStuff() {}');

      final otherFile = AssetId('a', 'lib/input.notdart');
      readerWriter.testing.writeString(otherFile, 'Not a Dart file');

      final builder = TestBuilder(
        buildExtensions: {
          '.dart': ['.a.dart'],
        },
        build: expectAsync2((buildStep, _) async {
          final other = buildStep.inputId.changeExtension('.notdart');
          expect(await buildStep.canRead(other), true);
          expect(await buildStep.resolver.isLibrary(other), false);
        }),
      );
      final resolvers = createResolvers();
      await runBuilder(
        builder,
        [input],
        SingleStepReaderWriter.fakeFor(readerWriter),
        resolvers,
      );
    },
  );

  group('compilationUnitFor', () {
    test('can parse a given input', () {
      return resolveSources({'a|web/main.dart': ' main() {}'}, (
        resolver,
      ) async {
        final unit = await resolver.compilationUnitFor(entryPoint);
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
      }, resolvers: createResolvers());
    });
  });

  group('astNodeFor', () {
    test('can return an unresolved ast', () {
      return resolveSources({'a|web/main.dart': ' main() {}'}, (
        resolver,
      ) async {
        final lib = await resolver.libraryFor(entryPoint);
        final unit = await resolver.astNodeFor(
          lib.topLevelFunctions.first.firstFragment,
        );
        expect(unit, isA<FunctionDeclaration>());
        expect(unit!.toSource(), 'main() {}');
        expect((unit as FunctionDeclaration).declaredFragment, isNull);
      }, resolvers: createResolvers());
    });

    test('can return an resolved ast', () {
      return resolveSources({'a|web/main.dart': 'main() {}'}, (resolver) async {
        final lib = await resolver.libraryFor(entryPoint);
        final unit = await resolver.astNodeFor(
          lib.topLevelFunctions.first.firstFragment,
          resolve: true,
        );
        expect(
          unit,
          isA<FunctionDeclaration>()
              .having((fd) => fd.toSource(), 'toSource()', 'main() {}')
              .having(
                (fd) => fd.declaredFragment,
                'declaredElement',
                isNotNull,
              ),
        );
      }, resolvers: createResolvers());
    });

    test('can return a resolved compilation unit', () {
      return resolveSources({'a|web/main.dart': 'main() {}'}, (resolver) async {
        final lib = await resolver.libraryFor(entryPoint);
        final unit = await resolver.astNodeFor(
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
              .having(
                (fd) => fd.declaredFragment,
                'declaredFragment',
                isNotNull,
              ),
        );
      });
    });
  });
}

final _skipOnPreRelease =
    Version.parse(Platform.version.split(' ').first).isPreRelease
        ? 'Skipped on prerelease sdks'
        : null;

abstract class ResolversFactory {
  /// Whether [create] returns a shared instance that persists between tests.
  Resolvers create({PackageConfig? packageConfig});
}

class AnalysisDriverModelFactory implements ResolversFactory {
  @override
  Resolvers create({PackageConfig? packageConfig}) => AnalyzerResolvers.custom(
    packageConfig: packageConfig,
    analysisDriverModel: AnalysisDriverModel(),
  );

  @override
  String toString() => 'New resolver';
}

class SharedAnalysisDriverModelFactory implements ResolversFactory {
  static final AnalysisDriverModel sharedInstance = AnalysisDriverModel();

  @override
  Resolvers create({PackageConfig? packageConfig}) {
    final result = AnalyzerResolvers.custom(
      packageConfig: packageConfig,
      analysisDriverModel: sharedInstance,
    );
    addTearDown(result.reset);
    return result;
  }

  @override
  String toString() => 'Shared new resolver';
}

Future<void> _resetResolvers(Resolvers resolvers) async {
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
}
