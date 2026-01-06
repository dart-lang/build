// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/src/build_plan/apply_builders.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
import 'package:build_runner/src/build_plan/phase.dart';
import 'package:build_runner/src/build_plan/target_graph.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/exceptions.dart';
import 'package:built_collection/built_collection.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  group('apply_builders.createBuildPhases', () {
    test('builderConfigOverrides overrides builder config globally', () async {
      final packageGraph = buildPackageGraph({
        rootPackage('a'): ['b'],
        package('b'): [],
      });
      final targetGraph = await TargetGraph.forPackageGraph(
        packageGraph: packageGraph,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['**'].build(),
        ),
      );
      final builderApplications = [
        apply('b:cool_builder', [CoolBuilder.new], toAllPackages()),
      ];
      final phases = await createBuildPhases(
        targetGraph,
        builderApplications,
        {
          'b:cool_builder': {'option_a': 'a', 'option_c': 'c'}.build(),
        }.build(),
        false,
      );
      for (final phase in phases.inBuildPhases) {
        expect((phase.builder as CoolBuilder).optionA, equals('a'));
        expect((phase.builder as CoolBuilder).optionB, equals('defaultB'));
        expect((phase.builder as CoolBuilder).optionC, equals('c'));
      }
    });

    test(
      'applies root package global options before builderConfigOverrides',
      () async {
        final packageGraph = buildPackageGraph({
          rootPackage('a'): ['b'],
          package('b'): [],
        });
        await runInBuildConfigZone(
          () async {
            final overrides =
                {
                  'a': BuildConfig(
                    packageName: 'a',
                    buildTargets: {
                      'a:a': BuildTarget(dependencies: {'b:b'}),
                    },
                    globalOptions: {
                      'b:cool_builder': GlobalBuilderConfig(
                        options: const {
                          'option_a': 'global a',
                          'option_b': 'global b',
                        },
                        releaseOptions: const {'option_b': 'release global b'},
                      ),
                    },
                  ),
                }.build();
            final targetGraph = await TargetGraph.forPackageGraph(
              packageGraph: packageGraph,
              testingOverrides: TestingOverrides(
                defaultRootPackageSources: ['**'].build(),
                buildConfig: overrides,
              ),
            );
            final builderApplications = [
              apply('b:cool_builder', [CoolBuilder.new], toAllPackages()),
            ];
            final phases = await createBuildPhases(
              targetGraph,
              builderApplications,
              {
                'b:cool_builder': {'option_c': '--define c'}.build(),
              }.build(),
              true,
            );
            for (final phase in phases.inBuildPhases) {
              expect(
                (phase.builder as CoolBuilder).optionA,
                equals('global a'),
              );
              expect(
                (phase.builder as CoolBuilder).optionB,
                equals('release global b'),
              );
              expect(
                (phase.builder as CoolBuilder).optionC,
                equals('--define c'),
              );
            }
          },
          packageGraph.currentPackage.name,
          packageGraph.currentPackage.dependencies
              .map((node) => node.name)
              .toList(),
        );
      },
    );

    test('honors package filter', () async {
      final packageGraph = buildPackageGraph({
        rootPackage('a'): ['b'],
        package('b'): [],
      });
      final targetGraph = await TargetGraph.forPackageGraph(
        packageGraph: packageGraph,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['**'].build(),
        ),
      );
      final builderApplications = [
        apply('b:cool_builder', [CoolBuilder.new], toDependentsOf('b')),
      ];
      final phases = await createBuildPhases(
        targetGraph,
        builderApplications,
        BuiltMap(),
        false,
      );
      expect(phases, hasLength(1));
      expect(phases.inBuildPhases.first.package, 'a');
    });

    test('honors appliesBuilders', () async {
      final packageGraph = buildPackageGraph({
        rootPackage('a'): ['b'],
        package('b'): [],
      });
      final targetGraph = await TargetGraph.forPackageGraph(
        packageGraph: packageGraph,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['**'].build(),
        ),
      );
      final builderApplications = [
        apply(
          'b:cool_builder',
          [CoolBuilder.new],
          toDependentsOf('b'),
          appliesBuilders: ['b:not_by_default'],
        ),
        apply('b:not_by_default', [(_) => TestBuilder()], toNoneByDefault()),
      ];
      final phases = await createBuildPhases(
        targetGraph,
        builderApplications,
        BuiltMap(),
        false,
      );
      expect(phases, hasLength(2));
      expect(
        phases.inBuildPhases,
        everyElement(
          const TypeMatcher<InBuildPhase>().having(
            (p) => p.package,
            'package',
            'a',
          ),
        ),
      );
    });

    test('skips non-hidden builders on non-root packages', () async {
      final packageGraph = buildPackageGraph({
        rootPackage('a'): ['b', 'c'],
        package('b'): ['c'],
        package('c'): [],
      });
      final targetGraph = await TargetGraph.forPackageGraph(
        packageGraph: packageGraph,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['**'].build(),
        ),
      );
      final builderApplications = [
        apply(
          'c:cool_builder',
          [CoolBuilder.new],
          toDependentsOf('c'),
          hideOutput: false,
        ),
      ];
      final phases = await createBuildPhases(
        targetGraph,
        builderApplications,
        BuiltMap(),
        false,
      );
      expect(phases, hasLength(1));
      expect(
        phases.inBuildPhases,
        everyElement(
          const TypeMatcher<InBuildPhase>().having(
            (p) => p.package,
            'package',
            'a',
          ),
        ),
      );
    });

    test(
      'skips builders which apply non-hidden builders on non-root packages',
      () async {
        final packageGraph = buildPackageGraph({
          rootPackage('a'): ['b', 'c'],
          package('b'): ['c'],
          package('c'): [],
        });
        final targetGraph = await TargetGraph.forPackageGraph(
          packageGraph: packageGraph,
          testingOverrides: TestingOverrides(
            defaultRootPackageSources: ['**'].build(),
          ),
        );
        final builderApplications = [
          apply(
            'c:cool_builder',
            [CoolBuilder.new],
            toDependentsOf('c'),
            appliesBuilders: ['c:not_by_default'],
          ),
          apply(
            'c:not_by_default',
            [(_) => TestBuilder()],
            toNoneByDefault(),
            hideOutput: false,
          ),
        ];
        final phases = await createBuildPhases(
          targetGraph,
          builderApplications,
          BuiltMap(),
          false,
        );
        expect(phases, hasLength(2));
        expect(
          phases.inBuildPhases,
          everyElement(
            const TypeMatcher<InBuildPhase>().having(
              (p) => p.package,
              'package',
              'a',
            ),
          ),
        );
      },
    );

    test('returns empty phases if a dependency is missing', () async {
      final packageGraph = buildPackageGraph({
        rootPackage('a'): ['b'],
        package('b'): [],
      });
      await runInBuildConfigZone(
        () async {
          final overrides =
              {
                'a': BuildConfig(
                  packageName: 'a',
                  buildTargets: {
                    'a:a': BuildTarget(dependencies: {'b:not_default'}),
                  },
                ),
              }.build();
          final targetGraph = await TargetGraph.forPackageGraph(
            packageGraph: packageGraph,
            testingOverrides: TestingOverrides(
              defaultRootPackageSources: ['**'].build(),
              buildConfig: overrides,
            ),
          );
          final builderApplications = [
            apply('b:cool_builder', [CoolBuilder.new], toAllPackages()),
          ];
          expect(
            () => createBuildPhases(
              targetGraph,
              builderApplications,
              BuiltMap(),
              false,
            ),
            throwsA(const TypeMatcher<CannotBuildException>()),
          );
        },
        packageGraph.currentPackage.name,
        packageGraph.currentPackage.dependencies
            .map((node) => node.name)
            .toList(),
      );
    });

    group('autoApplyBuilders', () {
      Future<BuildPhases> createPhases({
        Map<String, TargetBuilderConfig>? builderConfigs,
      }) async {
        final packageGraph = buildPackageGraph({
          rootPackage('a'): ['b'],
          package('b'): [],
        });
        final targetGraph = await runInBuildConfigZone(
          () => TargetGraph.forPackageGraph(
            packageGraph: packageGraph,
            testingOverrides: TestingOverrides(
              defaultRootPackageSources: ['**'].build(),
              buildConfig:
                  {
                    'a': BuildConfig(
                      packageName: 'a',
                      buildTargets: {
                        'a|a': BuildTarget(
                          autoApplyBuilders: false,
                          builders: builderConfigs,
                        ),
                      },
                    ),
                  }.build(),
            ),
          ),
          'a',
          [],
        );
        final builderApplications = [
          apply(
            'b:cool_builder',
            [CoolBuilder.new],
            toDependentsOf('b'),
            appliesBuilders: ['b:cool_builder_2'],
          ),
          apply('b:cool_builder_2', [CoolBuilder.new], toDependentsOf('b')),
        ];
        return await createBuildPhases(
          targetGraph,
          builderApplications,
          BuiltMap(),
          false,
        );
      }

      test('can be disabled for a target', () async {
        final phases = await createPhases();
        expect(phases.inBuildPhases, isEmpty);
      });

      test('individual builders can still be enabled', () async {
        final phases = await createPhases(
          builderConfigs: {
            'b:cool_builder_2': TargetBuilderConfig(isEnabled: true),
          },
        );
        expect(phases, hasLength(1));
        expect(
          phases.inBuildPhases.first,
          isA<InBuildPhase>()
              .having((p) => p.package, 'package', 'a')
              .having((p) => p.displayName, 'builderLabel', 'b:cool_builder_2'),
        );
      });

      test(
        'enabling a builder also enables other builders it applies',
        () async {
          final phases = await createPhases(
            builderConfigs: {
              'b:cool_builder': TargetBuilderConfig(isEnabled: true),
            },
          );
          expect(phases, hasLength(2));
          expect(
            phases.inBuildPhases,
            equals([
              isA<InBuildPhase>()
                  .having((p) => p.package, 'package', 'a')
                  .having(
                    (p) => p.displayName,
                    'builderLabel',
                    'b:cool_builder',
                  ),
              isA<InBuildPhase>()
                  .having((p) => p.package, 'package', 'a')
                  .having(
                    (p) => p.displayName,
                    'builderLabel',
                    'b:cool_builder_2',
                  ),
            ]),
          );
        },
      );
    });
  });

  test('does not allow post process builders with capturing inputs', () async {
    final packageGraph = buildPackageGraph({rootPackage('a'): []});
    final targetGraph = await TargetGraph.forPackageGraph(
      packageGraph: packageGraph,
      testingOverrides: TestingOverrides(
        defaultRootPackageSources: ['**'].build(),
      ),
    );
    final builderApplications = [
      apply(
        'a:regular',
        [(_) => TestBuilder()],
        toAllPackages(),
        appliesBuilders: ['a:post'],
      ),
      applyPostProcess('a:post', (_) => _InvalidPostProcessBuilder()),
    ];

    expect(
      () => createBuildPhases(
        targetGraph,
        builderApplications,
        BuiltMap(),
        false,
      ),
      throwsA(isArgumentError),
    );
  });
}

class CoolBuilder extends Builder {
  final String optionA;
  final String optionB;
  final String optionC;

  CoolBuilder(BuilderOptions options)
    : optionA = options.config['option_a'] as String? ?? 'defaultA',
      optionB = options.config['option_b'] as String? ?? 'defaultB',
      optionC = options.config['option_c'] as String? ?? 'defaultC';

  @override
  final buildExtensions = {
    '.txt': ['.out'],
  };

  @override
  Future build(BuildStep buildStep) async => throw UnimplementedError();
}

class _InvalidPostProcessBuilder extends PostProcessBuilder {
  @override
  FutureOr<void> build(PostProcessBuildStep buildStep) {}

  @override
  Iterable<String> get inputExtensions => const ['lib/{{}}.dart'];
}
