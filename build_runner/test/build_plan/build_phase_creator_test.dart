// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart'
    hide AutoApply, BuilderDefinition, PostProcessBuilderDefinition;
import 'package:build_runner/src/build_plan/build_configs.dart';
import 'package:build_runner/src/build_plan/build_package.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/build_phase_creator.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
import 'package:build_runner/src/build_plan/builder_definition.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:build_runner/src/build_plan/phase.dart';
import 'package:build_runner/src/build_plan/testing_overrides.dart';
import 'package:build_runner/src/exceptions.dart';
import 'package:built_collection/built_collection.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  group('BuildPhaseCreator', () {
    final buildPackages = BuildPackages.singlePackageBuild('a', [
      BuildPackage.forTesting(name: 'a', dependencies: ['b'], isOutput: true),
      BuildPackage.forTesting(name: 'b'),
    ]);

    test('builderConfigOverrides overrides builder config globally', () async {
      final buildConfigs = await BuildConfigs.load(
        buildPackages: buildPackages,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['**'].build(),
        ),
      );
      final phases =
          await BuildPhaseCreator(
            builderFactories: BuilderFactories({
              'b:cool_builder': [CoolBuilder.new],
            }),
            buildPackages: buildPackages,
            buildConfigs: buildConfigs,
            builderDefinitions: [
              BuilderDefinition(
                'b:cool_builder',
                autoApply: AutoApply.allPackages,
              ),
            ],
            builderConfigOverrides:
                {
                  'b:cool_builder': {'option_a': 'a', 'option_c': 'c'}.build(),
                }.build(),
            isReleaseBuild: false,
          ).createBuildPhases();
      for (final phase in phases.inBuildPhases) {
        expect((phase.builder as CoolBuilder).optionA, equals('a'));
        expect((phase.builder as CoolBuilder).optionB, equals('defaultB'));
        expect((phase.builder as CoolBuilder).optionC, equals('c'));
      }
    });

    test(
      'applies root package global options before builderConfigOverrides',
      () async {
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
            final buildConfigs = await BuildConfigs.load(
              buildPackages: buildPackages,
              testingOverrides: TestingOverrides(
                defaultRootPackageSources: ['**'].build(),
                buildConfig: overrides,
              ),
            );
            final phases =
                await BuildPhaseCreator(
                  builderFactories: BuilderFactories({
                    'b:cool_builder': [CoolBuilder.new],
                  }),
                  buildPackages: buildPackages,
                  buildConfigs: buildConfigs,
                  builderDefinitions: [
                    BuilderDefinition(
                      'b:cool_builder',
                      autoApply: AutoApply.allPackages,
                    ),
                  ],
                  builderConfigOverrides:
                      {
                        'b:cool_builder': {'option_c': '--define c'}.build(),
                      }.build(),
                  isReleaseBuild: true,
                ).createBuildPhases();
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
          buildPackages.singleOutputPackage!,
          buildPackages[buildPackages.singleOutputPackage!]!.dependencies
              .toList(),
        );
      },
    );

    test('honors package filter', () async {
      final buildConfigs = await BuildConfigs.load(
        buildPackages: buildPackages,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['**'].build(),
        ),
      );
      final phases =
          await BuildPhaseCreator(
            builderFactories: BuilderFactories({
              'b:cool_builder': [CoolBuilder.new],
            }),
            buildPackages: buildPackages,
            buildConfigs: buildConfigs,
            builderDefinitions: [
              BuilderDefinition(
                'b:cool_builder',
                autoApply: AutoApply.dependents,
              ),
            ],
            builderConfigOverrides: BuiltMap(),
            isReleaseBuild: false,
          ).createBuildPhases();
      expect(phases, hasLength(1));
      expect(phases.inBuildPhases.first.package, 'a');
    });

    test('honors appliesBuilders', () async {
      final buildConfigs = await BuildConfigs.load(
        buildPackages: buildPackages,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['**'].build(),
        ),
      );
      final builderDefinitions = [
        BuilderDefinition(
          'b:cool_builder',
          autoApply: AutoApply.dependents,
          appliesBuilders: ['b:not_by_default'],
        ),
        BuilderDefinition('b:not_by_default', autoApply: AutoApply.none),
      ];
      final phases =
          await BuildPhaseCreator(
            builderFactories: BuilderFactories({
              'b:cool_builder': [CoolBuilder.new],
              'b:not_by_default': [(_) => TestBuilder()],
            }),
            buildPackages: buildPackages,
            buildConfigs: buildConfigs,
            builderDefinitions: builderDefinitions,
            builderConfigOverrides: BuiltMap(),
            isReleaseBuild: false,
          ).createBuildPhases();
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
      final buildPackages = BuildPackages.singlePackageBuild('a', [
        BuildPackage.forTesting(
          name: 'a',
          dependencies: ['b', 'c'],
          isOutput: true,
        ),
        BuildPackage.forTesting(name: 'b', dependencies: ['c']),
        BuildPackage.forTesting(name: 'c'),
      ]);
      final buildConfigs = await BuildConfigs.load(
        buildPackages: buildPackages,
        testingOverrides: TestingOverrides(
          defaultRootPackageSources: ['**'].build(),
        ),
      );
      final phases =
          await BuildPhaseCreator(
            builderFactories: BuilderFactories({
              'c:cool_builder': [CoolBuilder.new],
            }),
            buildPackages: buildPackages,
            buildConfigs: buildConfigs,
            builderDefinitions: [
              BuilderDefinition(
                'c:cool_builder',
                autoApply: AutoApply.dependents,
                hideOutput: false,
              ),
            ],
            builderConfigOverrides: BuiltMap(),
            isReleaseBuild: false,
          ).createBuildPhases();
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
        final buildPackages = BuildPackages.singlePackageBuild('a', [
          BuildPackage.forTesting(
            name: 'a',
            dependencies: ['b', 'c'],
            isOutput: true,
          ),
          BuildPackage.forTesting(name: 'b', dependencies: ['c']),
          BuildPackage.forTesting(name: 'c'),
        ]);
        final buildConfigs = await BuildConfigs.load(
          buildPackages: buildPackages,
          testingOverrides: TestingOverrides(
            defaultRootPackageSources: ['**'].build(),
          ),
        );
        final builderDefinitions = [
          BuilderDefinition(
            'c:cool_builder',
            autoApply: AutoApply.dependents,
            appliesBuilders: ['c:not_by_default'],
          ),
          BuilderDefinition(
            'c:not_by_default',
            autoApply: AutoApply.none,
            hideOutput: false,
          ),
        ];
        final phases =
            await BuildPhaseCreator(
              builderFactories: BuilderFactories({
                'c:cool_builder': [CoolBuilder.new],
                'c:not_by_default': [(_) => TestBuilder()],
              }),
              buildPackages: buildPackages,
              buildConfigs: buildConfigs,
              builderDefinitions: builderDefinitions,
              builderConfigOverrides: BuiltMap(),
              isReleaseBuild: false,
            ).createBuildPhases();
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
          final buildConfigs = await BuildConfigs.load(
            buildPackages: buildPackages,
            testingOverrides: TestingOverrides(
              defaultRootPackageSources: ['**'].build(),
              buildConfig: overrides,
            ),
          );
          expect(
            () =>
                BuildPhaseCreator(
                  builderFactories: BuilderFactories({
                    'b:cool_builder': [CoolBuilder.new],
                  }),
                  buildPackages: buildPackages,
                  buildConfigs: buildConfigs,
                  builderDefinitions: [
                    BuilderDefinition(
                      'b:cool_builder',
                      autoApply: AutoApply.allPackages,
                    ),
                  ],
                  builderConfigOverrides: BuiltMap(),
                  isReleaseBuild: false,
                ).createBuildPhases(),
            throwsA(const TypeMatcher<CannotBuildException>()),
          );
        },
        buildPackages.singleOutputPackage!,
        buildPackages[buildPackages.singleOutputPackage!]!.dependencies
            .toList(),
      );
    });

    group('autoApplyBuilders', () {
      Future<BuildPhases> createPhases({
        Map<String, TargetBuilderConfig>? builderConfigs,
      }) async {
        final buildConfigs = await runInBuildConfigZone(
          () => BuildConfigs.load(
            buildPackages: buildPackages,
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
        final builderDefinitions = [
          BuilderDefinition(
            'b:cool_builder',
            autoApply: AutoApply.dependents,
            appliesBuilders: ['b:cool_builder_2'],
          ),
          BuilderDefinition(
            'b:cool_builder_2',
            autoApply: AutoApply.dependents,
          ),
        ];
        return await BuildPhaseCreator(
          builderFactories: BuilderFactories({
            'b:cool_builder': [CoolBuilder.new],
            'b:cool_builder_2': [CoolBuilder.new],
          }),
          buildPackages: buildPackages,
          buildConfigs: buildConfigs,
          builderDefinitions: builderDefinitions,
          builderConfigOverrides: BuiltMap(),
          isReleaseBuild: false,
        ).createBuildPhases();
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

    test(
      'does not allow post process builders with capturing inputs',
      () async {
        final buildPackages = BuildPackages.singlePackageBuild('a', [
          BuildPackage.forTesting(name: 'a', isOutput: true),
        ]);
        final buildConfigs = await BuildConfigs.load(
          buildPackages: buildPackages,
          testingOverrides: TestingOverrides(
            defaultRootPackageSources: ['**'].build(),
          ),
        );
        final builderDefinitions = [
          BuilderDefinition(
            'a:regular',
            autoApply: AutoApply.allPackages,
            appliesBuilders: ['a:post'],
          ),
          PostProcessBuilderDefinition('a:post'),
        ];

        expect(
          () =>
              BuildPhaseCreator(
                builderFactories: BuilderFactories(
                  {
                    'a:regular': [CoolBuilder.new],
                  },
                  postProcessBuilderFactories: {
                    'a:post': (_) => _InvalidPostProcessBuilder(),
                  },
                ),
                buildPackages: buildPackages,
                buildConfigs: buildConfigs,
                builderDefinitions: builderDefinitions,
                builderConfigOverrides: BuiltMap(),
                isReleaseBuild: false,
              ).createBuildPhases(),
          throwsA(isArgumentError),
        );
      },
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
