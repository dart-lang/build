// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:build_web_compilers/src/build_modules/build_modules.dart';
import 'package:test/test.dart';

void main() {
  final platform = DartPlatform.register('test', ['html']);

  group('computeTransitiveDeps', () {
    final rootId = AssetId('a', 'lib/a.dart');
    final directDepId = AssetId('a', 'lib/src/dep.dart');
    final transitiveDepId = AssetId('b', 'lib/b.dart');
    final deepTransitiveDepId = AssetId('b', 'lib/src/dep.dart');
    final rootModule = Module(rootId, [rootId], [directDepId], platform, true);
    final directDepModule = Module(
      directDepId,
      [directDepId],
      [transitiveDepId],
      platform,
      true,
    );
    final transitiveDepModule = Module(
      transitiveDepId,
      [transitiveDepId],
      [deepTransitiveDepId],
      platform,
      true,
    );
    final deepTransitiveDepModule = Module(
      deepTransitiveDepId,
      [deepTransitiveDepId],
      [],
      platform,
      true,
    );

    test('finds transitive deps', () async {
      // package:build_test's testBuilder swallows exceptions thrown inside the
      // async build callback because of the build runner's zone boundary.
      // We capture and store any exception here, then rethrow it at the end
      // of the test body to ensure test failures are correctly propagated.
      Object? failure;
      await testBuilder(
        TestBuilder(
          buildExtensions: {
            'lib/a${moduleExtension(platform)}': ['.transitive'],
          },
          build: expectAsync2((buildStep, _) async {
            try {
              final transitiveDeps =
                  (await rootModule.computeTransitiveDependencies(
                    buildStep,
                  )).map((m) => m.primarySource).toList();
              expect(
                transitiveDeps,
                unorderedEquals([
                  directDepModule.primarySource,
                  transitiveDepModule.primarySource,
                  deepTransitiveDepModule.primarySource,
                ]),
              );
              expect(
                transitiveDeps.indexOf(transitiveDepModule.primarySource),
                lessThan(transitiveDeps.indexOf(directDepModule.primarySource)),
              );
              expect(
                transitiveDeps.indexOf(deepTransitiveDepModule.primarySource),
                lessThan(
                  transitiveDeps.indexOf(transitiveDepModule.primarySource),
                ),
              );
            } catch (e) {
              failure = e;
            }
          }),
        ),
        {
          'a|lib/a${moduleExtension(platform)}': jsonEncode(
            rootModule.toJson(),
          ),
          'a|lib/src/dep${moduleExtension(platform)}': jsonEncode(
            directDepModule.toJson(),
          ),
          'b|lib/b${moduleExtension(platform)}': jsonEncode(
            transitiveDepModule.toJson(),
          ),
          'b|lib/src/dep${moduleExtension(platform)}': jsonEncode(
            deepTransitiveDepModule.toJson(),
          ),
        },
      );
      if (failure != null) {
        // ignore: only_throw_errors
        throw failure!;
      }
    });

    test('missing modules report nice errors', () async {
      // package:build_test's testBuilder swallows exceptions thrown inside the
      // async build callback because of the build runner's zone boundary.
      // We capture and store any exception here, then rethrow it at the end
      // of the test body to ensure test failures are correctly propagated.
      Object? failure;
      await testBuilder(
        TestBuilder(
          buildExtensions: {
            'lib/a${moduleExtension(platform)}': ['.transitive'],
          },
          build: expectAsync2((buildStep, _) async {
            try {
              await expectLater(
                () => rootModule.computeTransitiveDependencies(buildStep),
                throwsA(
                  isA<MissingModulesException>().having(
                    (e) => e.message,
                    'message',
                    contains('''
Unable to find modules for some sources, this is usually the result of either a
bad import, a missing dependency in a package (or possibly a dev_dependency
needs to move to a real dependency), or a build failure (if importing a
generated file).

Please check the following imports:

`import 'src/dep.dart';` from b|lib/b.dart at 1:1
'''),
                  ),
                ),
              );
            } catch (e) {
              failure = e;
            }
          }),
        ),
        {
          'a|lib/a${moduleExtension(platform)}': jsonEncode(
            rootModule.toJson(),
          ),
          'a|lib/src/dep${moduleExtension(platform)}': jsonEncode(
            directDepModule.toJson(),
          ),
          'b|lib/b${moduleExtension(platform)}': jsonEncode(
            transitiveDepModule.toJson(),
          ),
          // No module for b|lib/src/dep.dart
          'b|lib/b.dart': 'import \'src/dep.dart\';',
        },
      );
      if (failure != null) {
        // ignore: only_throw_errors
        throw failure!;
      }
    });

    test('missing conditional imports yield helpful errors', () async {
      await testBuilder(
        TestBuilder(
          buildExtensions: {
            'lib/a${moduleExtension(platform)}': ['.transitive'],
          },
          build: expectAsync2((buildStep, _) async {
            await expectLater(
              () => rootModule.computeTransitiveDependencies(buildStep),
              throwsA(
                isA<MissingModulesException>().having(
                  (e) => e.message,
                  'message',
                  contains('''
Unable to find modules for some sources, this is usually the result of either a
bad import, a missing dependency in a package (or possibly a dev_dependency
needs to move to a real dependency), or a build failure (if importing a
generated file).

Please check the following imports:

`import 'some_other_dep.dart' if (dart.library.js_interop) 'src/dep.dart';` from b|lib/b.dart at 1:1
'''),
                ),
              ),
            );
          }),
        ),
        {
          'a|lib/a${moduleExtension(platform)}': jsonEncode(
            rootModule.toJson(),
          ),
          'a|lib/src/dep${moduleExtension(platform)}': jsonEncode(
            directDepModule.toJson(),
          ),
          'b|lib/b${moduleExtension(platform)}': jsonEncode(
            transitiveDepModule.toJson(),
          ),
          // No module for b|lib/src/dep.dart
          'b|lib/b.dart':
              'import \'some_other_dep.dart\' if (dart.library.js_interop) \'src/dep.dart\';',
        },
      );
    });

    group('unsupported modules', () {
      test('are not allowed as the root', () async {
        final unsupportedRootModule = Module(
          rootId,
          [rootId],
          [directDepId],
          platform,
          false,
        );

        await testBuilder(
          TestBuilder(
            buildExtensions: {
              'lib/a${moduleExtension(platform)}': ['.transitive'],
            },
            build: expectAsync2((buildStep, _) async {
              await expectLater(
                () => rootModule.computeTransitiveDependencies(
                  buildStep,
                  throwIfUnsupported: true,
                ),
                throwsA(
                  isA<UnsupportedModules>().having(
                    (e) => e.unsupportedModules.map((m) => m.primarySource),
                    'unsupportedModules',
                    equals([unsupportedRootModule.primarySource]),
                  ),
                ),
              );
            }),
          ),
          {
            'a|lib/a${moduleExtension(platform)}': jsonEncode(
              unsupportedRootModule.toJson(),
            ),
            'a|lib/src/dep${moduleExtension(platform)}': jsonEncode(
              directDepModule.toJson(),
            ),
            'b|lib/b${moduleExtension(platform)}': jsonEncode(
              transitiveDepModule.toJson(),
            ),
            'b|lib/src/dep${moduleExtension(platform)}': jsonEncode(
              deepTransitiveDepModule.toJson(),
            ),
          },
        );
      });

      test('are not allowed in immediate deps', () async {
        final unsupportedDirectDepModule = Module(
          directDepId,
          [directDepId],
          [transitiveDepId],
          platform,
          false,
        );

        await testBuilder(
          TestBuilder(
            buildExtensions: {
              'lib/a${moduleExtension(platform)}': ['.transitive'],
            },
            build: expectAsync2((buildStep, _) async {
              await expectLater(
                () => rootModule.computeTransitiveDependencies(
                  buildStep,
                  throwIfUnsupported: true,
                ),
                throwsA(
                  isA<UnsupportedModules>().having(
                    (e) => e.unsupportedModules.map((m) => m.primarySource),
                    'unsupportedModules',
                    equals([unsupportedDirectDepModule.primarySource]),
                  ),
                ),
              );
            }),
          ),
          {
            'a|lib/a${moduleExtension(platform)}': jsonEncode(
              rootModule.toJson(),
            ),
            'a|lib/src/dep${moduleExtension(platform)}': jsonEncode(
              unsupportedDirectDepModule.toJson(),
            ),
            'b|lib/b${moduleExtension(platform)}': jsonEncode(
              transitiveDepModule.toJson(),
            ),
            'b|lib/src/dep${moduleExtension(platform)}': jsonEncode(
              deepTransitiveDepModule.toJson(),
            ),
          },
        );
      });

      test('are not allowed in transitive deps', () async {
        final unsupportedTransitiveDepDepModule = Module(
          transitiveDepId,
          [transitiveDepId],
          [deepTransitiveDepId],
          platform,
          false,
        );

        await testBuilder(
          TestBuilder(
            buildExtensions: {
              'lib/a${moduleExtension(platform)}': ['.transitive'],
            },
            build: expectAsync2((buildStep, _) async {
              await expectLater(
                () => rootModule.computeTransitiveDependencies(
                  buildStep,
                  throwIfUnsupported: true,
                ),
                throwsA(
                  isA<UnsupportedModules>().having(
                    (e) => e.unsupportedModules.map((m) => m.primarySource),
                    'unsupportedModules',
                    equals([unsupportedTransitiveDepDepModule.primarySource]),
                  ),
                ),
              );
            }),
          ),
          {
            'a|lib/a${moduleExtension(platform)}': jsonEncode(
              rootModule.toJson(),
            ),
            'a|lib/src/dep${moduleExtension(platform)}': jsonEncode(
              directDepModule.toJson(),
            ),
            'b|lib/b${moduleExtension(platform)}': jsonEncode(
              unsupportedTransitiveDepDepModule.toJson(),
            ),
            'b|lib/src/dep${moduleExtension(platform)}': jsonEncode(
              deepTransitiveDepModule.toJson(),
            ),
          },
        );
      });
    });

    group('circular dependencies', () {
      test('do not crash on when involving the root module', () async {
        // A <-> B
        final moduleA = Module(rootId, [rootId], [directDepId], platform, true);
        final moduleB = Module(
          directDepId,
          [directDepId],
          [rootId],
          platform,
          true,
        );

        // The test builder swallows exceptions thrown inside its async zone
        // boundary, so we capture exceptions here, to ensure they're propagated
        // to the test framework.
        Object? failure;
        await testBuilder(
          TestBuilder(
            buildExtensions: {
              'lib/a${moduleExtension(platform)}': ['.transitive'],
            },
            build: expectAsync2((buildStep, _) async {
              try {
                final transitiveDeps =
                    (await moduleA.computeTransitiveDependencies(
                      buildStep,
                    )).map((m) => m.primarySource).toList();
                expect(transitiveDeps, contains(moduleB.primarySource));
              } catch (e) {
                failure = e;
              }
            }),
          ),
          {
            'a|lib/a${moduleExtension(platform)}': jsonEncode(moduleA.toJson()),
            'a|lib/src/dep${moduleExtension(platform)}': jsonEncode(
              moduleB.toJson(),
            ),
          },
        );
        if (failure != null) {
          // ignore: only_throw_errors
          throw failure!;
        }
      });

      test('do not crash when in transitive dependencies', () async {
        // A -> B, B <-> C
        final moduleA = Module(rootId, [rootId], [directDepId], platform, true);
        final moduleB = Module(
          directDepId,
          [directDepId],
          [transitiveDepId],
          platform,
          true,
        );
        final moduleC = Module(
          transitiveDepId,
          [transitiveDepId],
          [directDepId],
          platform,
          true,
        );

        // The test builder swallows exceptions thrown inside its async zone
        // boundary, so we capture exceptions here, to ensure they're propagated
        // to the test framework.
        Object? failure;
        await testBuilder(
          TestBuilder(
            buildExtensions: {
              'lib/a${moduleExtension(platform)}': ['.transitive'],
            },
            build: expectAsync2((buildStep, _) async {
              try {
                final transitiveDeps =
                    (await moduleA.computeTransitiveDependencies(
                      buildStep,
                    )).map((m) => m.primarySource).toList();
                expect(
                  transitiveDeps,
                  unorderedEquals([
                    moduleB.primarySource,
                    moduleC.primarySource,
                  ]),
                );
              } catch (e) {
                failure = e;
              }
            }),
          ),
          {
            'a|lib/a${moduleExtension(platform)}': jsonEncode(moduleA.toJson()),
            'a|lib/src/dep${moduleExtension(platform)}': jsonEncode(
              moduleB.toJson(),
            ),
            'b|lib/b${moduleExtension(platform)}': jsonEncode(moduleC.toJson()),
          },
        );
        if (failure != null) {
          // ignore: only_throw_errors
          throw failure!;
        }
      });
    });
  });
}
