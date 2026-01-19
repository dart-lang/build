// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:build/build.dart';
import 'package:build_config/build_config.dart'
    hide
        AutoApply,
        BuilderDefinition,
        PostProcessBuilderDefinition,
        TargetBuilderConfigDefaults;
import 'package:build_runner/src/build/asset_graph/graph.dart';
import 'package:build_runner/src/build/asset_graph/node.dart';
import 'package:build_runner/src/build/asset_graph/post_process_build_step_id.dart';
import 'package:build_runner/src/build/build_result.dart';
import 'package:build_runner/src/build/performance_tracker.dart';
import 'package:build_runner/src/build_plan/build_configs.dart';
import 'package:build_runner/src/build_plan/build_directory.dart';
import 'package:build_runner/src/build_plan/build_filter.dart';
import 'package:build_runner/src/build_plan/build_packages.dart';
import 'package:build_runner/src/build_plan/build_phases.dart';
import 'package:build_runner/src/build_plan/builder_definition.dart';
import 'package:build_runner/src/build_plan/builder_factories.dart';
import 'package:build_runner/src/constants.dart';
import 'package:build_runner/src/exceptions.dart';
import 'package:build_runner/src/io/reader_writer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

import '../common/common.dart';

void main() {
  /// Basic phases/phase groups which get used in many tests
  final testBuilder = TestBuilder(
    buildExtensions: appendExtension('.copy', from: '.txt'),
  );
  final requiresPostProcessBuilderDefinition = BuilderDefinition(
    'test_builder',
    autoApply: AutoApply.rootPackage,
    appliesBuilders: ['a:post_copy_builder'],
    hideOutput: false,
    isOptional: false,
  );
  final postCopyABuilderDefinition = PostProcessBuilderDefinition(
    'a:post_copy_builder',
  );
  final builderFactories = BuilderFactories(
    {
      '': [(_) => testBuilder],
      'test_builder': [(_) => testBuilder],
    },
    postProcessBuilderFactories: {
      'a:post_copy_builder':
          (options) => CopyingPostProcessBuilder(
            outputExtension: options.config['extension'] as String? ?? '.post',
          ),
    },
  );
  final globBuilder = GlobbingBuilder(Glob('**.txt'));
  final placeholders = placeholderIdsFor(
    createBuildPackages({rootPackage('a'): []}),
  );

  group('build', () {
    test('can log within a buildFactory', () async {
      await testBuilderFactories(
        [
          (_) {
            log.info('I can log!');
            return TestBuilder(buildExtensions: appendExtension('.1'));
          },
        ],
        {'a|web/a.txt': 'a'},
      );
    });

    test('Builder factories are only invoked once per application', () async {
      var invokedCount = 0;
      Builder builderFactory(_) {
        invokedCount += 1;
        return TestBuilder();
      }

      await testBuilderFactories(
        [builderFactory],
        {'a|lib/a.dart': '', 'b|lib/b.dart': ''},
      );

      // Once per package with inputs, once in `test_builder.dart` to get the
      // builder name.
      expect(invokedCount, 3);
    });

    test('throws an error if the builderFactory fails', () async {
      expect(
        () async => await testBuilderFactories(
          [
            (_) {
              throw StateError('some error');
            },
          ],
          {'a|web/a.txt': 'a'},
        ),
        throwsA(const TypeMatcher<CannotBuildException>()),
      );
    });

    test(
      'throws an error if any output extensions match input extensions',
      () async {
        await expectLater(
          () async => await testBuilderFactories(
            [
              (_) => TestBuilder(
                buildExtensions: {
                  '.dart': ['.g.dart', '.json'],
                  '.json': ['.dart'],
                },
              ),
            ],
            {'a|lib/a.dart': ''},
          ),
          throwsA(
            isA<ArgumentError>()
                .having((e) => e.name, 'name', 'TestBuilder.buildExtensions')
                .having(
                  (e) => e.message,
                  'message',
                  allOf(
                    contains('.json'),
                    contains('.dart'),
                    isNot(contains('.g.dart')),
                  ),
                ),
          ),
        );
      },
    );

    test('runs a max of one concurrent action per phase', () async {
      final assets = <String, String>{};
      for (var i = 0; i < 2; i++) {
        assets['a|web/$i.txt'] = '$i';
      }
      var concurrentCount = 0;
      var maxConcurrentCount = 0;
      final reachedMax = Completer<void>();
      await testBuilders(
        [
          TestBuilder(
            build: (_, _) async {
              concurrentCount += 1;
              maxConcurrentCount = math.max(
                concurrentCount,
                maxConcurrentCount,
              );
              if (concurrentCount >= 1 && !reachedMax.isCompleted) {
                await Future<void>.delayed(const Duration(milliseconds: 100));
                if (!reachedMax.isCompleted) reachedMax.complete(null);
              }
              await reachedMax.future;
              concurrentCount -= 1;
            },
          ),
        ],
        assets,
        outputs: {},
      );
      expect(maxConcurrentCount, 1);
    });

    group('with root package inputs', () {
      test('one phase, one builder, one-to-one outputs', () async {
        await testBuilders(
          [testBuilder],
          {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
          outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'},
        );
      });

      test('runs once per input not once per output', () async {
        var runs = 0;
        final testBuilder = TestBuilder(
          buildExtensions: {
            '.txt': ['.txt.1', '.txt.2'],
          },
          extraWork: (_, _) {
            ++runs;
          },
        );

        await testBuilders(
          [testBuilder],
          {'a|web/a.txt': ''},
          outputs: {'a|web/a.txt.1': '', 'a|web/a.txt.2': ''},
        );
        expect(runs, 1);
      });

      test('with a PostProcessBuilder', () async {
        TestBuilder builderFactory(_) => TestBuilder();
        await testBuilderFactories(
          [builderFactory],
          postProcessBuilderFactories: [
            (_) => CopyingPostProcessBuilder(outputExtension: '.post'),
          ],
          appliesBuilders: {
            builderFactory: ['CopyingPostProcessBuilder'],
          },
          {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
          outputs: {
            'a|web/a.txt.copy': 'a',
            'a|lib/b.txt.copy': 'b',
            'a|web/a.txt.post': 'a',
            'a|lib/b.txt.post': 'b',
          },
        );
      });

      test('with placeholder as input', () async {
        final builder1 = PlaceholderBuilder(
          {'lib.txt': 'libText'}.build(),
          inputPlaceholder: r'$lib$',
        );
        final builder2 = PlaceholderBuilder(
          {'root.txt': 'rootText'}.build(),
          inputPlaceholder: r'$package$',
        );
        await testBuilders(
          [builder1, builder2],
          {},
          visibleOutputBuilders: {builder1, builder2},
          rootPackage: 'a',
          outputs: {'a|lib/lib.txt': 'libText', 'a|root.txt': 'rootText'},
        );
      });

      test('one phase, one builder, one-to-many outputs', () async {
        await testPhases(
          BuilderFactories({
            '': [
              (_) => TestBuilder(
                buildExtensions: appendExtension('.copy', numCopies: 2),
              ),
            ],
          }),
          [BuilderDefinition('')],
          {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
          outputs: {
            'a|web/a.txt.copy.0': 'a',
            'a|web/a.txt.copy.1': 'a',
            'a|lib/b.txt.copy.0': 'b',
            'a|lib/b.txt.copy.1': 'b',
          },
        );
      });

      test('outputs with ^', () async {
        await testBuilders(
          [
            TestBuilder(
              buildExtensions: {
                '^pubspec.yaml': ['pubspec.yaml.copy'],
              },
            ),
          ],
          {'a|pubspec.yaml': 'a', 'a|lib/pubspec.yaml': 'a'},
          outputs: {'a|pubspec.yaml.copy': 'a'},
        );
      });

      test('outputs with a capture group', () async {
        await testBuilders(
          [
            TestBuilder(
              buildExtensions: {
                'assets/{{}}.txt': ['lib/src/generated/{{}}.dart'],
              },
            ),
          ],
          {'a|assets/nested/input/file.txt': 'a'},
          outputs: {'a|lib/src/generated/nested/input/file.dart': 'a'},
        );
      });

      test('recognizes right optional builder with capture groups', () async {
        final builder1 = TestBuilder(
          buildExtensions: {
            'assets/{{}}.txt': ['lib/src/generated/{{}}.dart'],
          },
        );
        final builder2 = TestBuilder(
          buildExtensions: {
            '.dart': ['.copy.dart'],
          },
        );
        await testBuilders(
          [builder1, builder2],
          {'a|assets/nested/input/file.txt': 'a'},
          optionalBuilders: {builder1},
          outputs: {
            'a|lib/src/generated/nested/input/file.dart': 'a',
            'a|lib/src/generated/nested/input/file.copy.dart': 'a',
          },
        );
      });

      test(
        'optional build actions don\'t run if their outputs aren\'t read',
        () async {
          final builder1 = TestBuilder(buildExtensions: appendExtension('.1'));
          final builder2 = TestBuilder(
            buildExtensions: appendExtension('.copy', from: '.1'),
          );
          await testBuilders(
            [builder1, builder2],
            optionalBuilders: {builder1, builder2},
            {'a|lib/a.txt': 'a'},
            outputs: {},
          );
        },
      );

      test('optional build actions do run if their outputs are read', () async {
        final builder1 = TestBuilder(buildExtensions: appendExtension('.1'));
        final builder2 = TestBuilder(
          buildExtensions: replaceExtension('.1', '.2'),
        );
        final builder3 = TestBuilder(
          buildExtensions: replaceExtension('.2', '.3'),
        );
        await testBuilders(
          [builder1, builder2, builder3],
          {'a|web/a.txt': 'a'},
          optionalBuilders: {builder1, builder2},
          outputs: {
            'a|web/a.txt.1': 'a',
            'a|web/a.txt.2': 'a',
            'a|web/a.txt.3': 'a',
          },
        );
      });

      test('multiple mixed build actions with custom build config', () async {
        final builders = [
          BuilderDefinition(''),
          BuilderDefinition(
            'a:clone_txt',
            autoApply: AutoApply.rootPackage,
            isOptional: true,
            hideOutput: false,
            appliesBuilders: ['a:post_copy_builder'],
          ),
          BuilderDefinition(
            'a:copy_web_clones',
            autoApply: AutoApply.rootPackage,
            hideOutput: false,
          ),
          postCopyABuilderDefinition,
        ];
        await testPhases(
          BuilderFactories(
            {
              '': [(_) => TestBuilder()],
              'a:clone_txt': [
                (_) => TestBuilder(buildExtensions: appendExtension('.clone')),
              ],
              'a:copy_web_clones': [
                (_) => TestBuilder(
                  buildExtensions: appendExtension('.copy', numCopies: 2),
                ),
              ],
            },
            postProcessBuilderFactories:
                builderFactories.postProcessBuilderFactories.toMap(),
          ),
          builders,
          {
            'a|web/a.txt': 'a',
            'a|lib/b.txt': 'b',
            'a|build.yaml': r'''
targets:
  a:
    builders:
      a:clone.txt:
        generate_for:
          - "**/*.txt"
      a:copy_web_clones:
        generate_for:
          - web/*.txt.clone
      a:post_copy_builder:
        options:
          extension: .custom.post
        generate_for:
          - web/*.txt
''',
          },
          outputs: {
            'a|web/a.txt.copy': 'a',
            'a|web/a.txt.clone': 'a',
            'a|lib/b.txt.copy': 'b',
            // No b.txt.clone since nothing else read it and its optional.
            'a|web/a.txt.clone.copy.0': 'a',
            'a|web/a.txt.clone.copy.1': 'a',
            r'$$a|web/a.txt.custom.post': 'a',
          },
        );
      });

      test('allows running on generated inputs that do not match target '
          'source globs', () async {
        final builders = [
          TestBuilder(buildExtensions: appendExtension('.1', from: '.txt')),
          TestBuilder(buildExtensions: appendExtension('.2', from: '.1')),
        ];
        await testBuilders(
          builders,
          {
            'a|lib/a.txt': 'a',
            'a|build.yaml': r'''
targets:
  $default:
    sources:
      - lib/*.txt
''',
          },
          outputs: {'a|lib/a.txt.1': 'a', 'a|lib/a.txt.1.2': 'a'},
        );
      });

      test('early step touches a not-yet-generated asset', () async {
        final copyId = AssetId('a', 'lib/file.a.copy');
        final builders = [
          TestBuilder(
            buildExtensions: appendExtension('.copy', from: '.b'),
            extraWork: (buildStep, _) => buildStep.canRead(copyId),
          ),
          TestBuilder(buildExtensions: appendExtension('.copy', from: '.a')),
          TestBuilder(
            buildExtensions: appendExtension('.exists', from: '.a'),
            build: writeCanRead(copyId),
          ),
        ];
        await testBuilders(
          builders,
          {'a|lib/file.a': 'a', 'a|lib/file.b': 'b'},
          outputs: {
            'a|lib/file.a.copy': 'a',
            'a|lib/file.b.copy': 'b',
            'a|lib/file.a.exists': 'true',
          },
        );
      });

      test('asset is deleted mid-build, use cached canRead result', () async {
        final aTxtId = AssetId('a', 'lib/file.a');
        final ready = Completer<void>();
        final firstBuilder = TestBuilder(
          buildExtensions: appendExtension('.exists', from: '.a'),
          build: writeCanRead(aTxtId),
        );
        final builders = [
          firstBuilder,
          TestBuilder(
            buildExtensions: appendExtension('.exists', from: '.b'),
            build: (_, _) => ready.future,
            extraWork: writeCanRead(aTxtId),
          ),
        ];

        // After the first builder runs, delete the asset from the in-memory
        // filesystem and allow the 2nd builder to run.
        final readerWriter = TestReaderWriter(rootPackage: 'a');
        unawaited(
          firstBuilder.buildsCompleted.first.then((id) {
            readerWriter.testing.delete(aTxtId);
            ready.complete();
          }),
        );

        await testBuilders(
          builders,
          {'a|lib/file.a': '', 'a|lib/file.b': ''},
          readerWriter: readerWriter,
          rootPackage: 'a',
          outputs: {
            'a|lib/file.a.exists': 'true',
            'a|lib/file.b.exists': 'true',
          },
        );
      });

      test('pre-existing outputs', () async {
        final result = await testPhases(
          BuilderFactories({
            '': [
              (_) => TestBuilder(
                buildExtensions: appendExtension('.copy', from: '.txt'),
              ),
            ],
            'b2': [
              (_) => TestBuilder(
                buildExtensions: appendExtension('.clone', from: '.copy'),
              ),
            ],
          }),
          [BuilderDefinition(''), BuilderDefinition('b2')],
          {'a|web/a.txt': 'a', 'a|web/a.txt.copy': 'a'},
          outputs: {'a|web/a.txt.copy': 'a', 'a|web/a.txt.copy.clone': 'a'},
        );

        final graphId = makeAssetId('a|$assetGraphPath');
        expect(result.readerWriter.testing.exists(graphId), isTrue);
        final cachedGraph =
            AssetGraph.deserialize(
              result.readerWriter.testing.readBytes(graphId),
            )!;
        expect(
          cachedGraph.allNodes.map((node) => node.id),
          unorderedEquals([
            makeAssetId('a|web/a.txt'),
            makeAssetId('a|web/a.txt.copy'),
            makeAssetId('a|web/a.txt.copy.clone'),
            ...placeholders,
          ]),
        );
        expect(cachedGraph.sources, [makeAssetId('a|web/a.txt')]);
        expect(
          cachedGraph.outputs,
          unorderedEquals([
            makeAssetId('a|web/a.txt.copy'),
            makeAssetId('a|web/a.txt.copy.clone'),
          ]),
        );
      });

      test('in low resources mode', () async {
        await testPhases(
          builderFactories,
          [BuilderDefinition('')],
          {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
          outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'},
          enableLowResourcesMode: true,
        );
      });

      test('previous outputs are cleaned up', () async {
        final result = await testBuilders(
          [testBuilder],
          {'a|web/a.txt': 'a'},
          outputs: {'a|web/a.txt.copy': 'a'},
        );

        final copyId = makeAssetId(
          'a|.dart_tool/build/generated/a/web/a.txt.copy',
        );
        expect(result.readerWriter.testing.exists(copyId), isTrue);

        final canReadInBuild = Completer<bool>();
        final blockingCompleter = Completer<void>();
        final builder = TestBuilder(
          buildExtensions: appendExtension('.copy', from: '.txt'),
          build: (buildStep, _) async {
            canReadInBuild.complete(await buildStep.canRead(copyId));
            await buildStep.writeAsString(
              copyId,
              await buildStep.readAsString(buildStep.inputId),
            );
            await blockingCompleter.future;
          },
        );
        final done = testBuilders(
          [builder],
          {'a|web/a.txt': 'b'},
          readerWriter: result.readerWriter,
        );

        // Before the build starts we should still see the asset, we haven't
        // actually deleted it yet.
        expect(result.readerWriter.testing.exists(copyId), isTrue);

        // But we should delete it before actually running the builder.
        final inputId = makeAssetId('a|web/a.txt');
        await builder.buildInputs.firstWhere((id) => id == inputId);

        // Because of write caching, it's not deleted from `readerWriter`.
        expect(result.readerWriter.testing.exists(copyId), isTrue);
        // ...but it is gone from the point of view of the build.
        expect(await canReadInBuild.future, isFalse);

        // Now let the build finish.
        blockingCompleter.complete();
        await done;
      });

      test('does not build hidden non-lib assets by default', () async {
        final result = await testPhases(
          builderFactories,
          [BuilderDefinition('', hideOutput: true)],
          {'a|example/a.txt': 'a', 'a|lib/b.txt': 'b'},
          checkBuildStatus: false,
          buildDirs: {BuildDirectory('web')},
        );

        checkBuild(
          result.buildResult,
          readerWriter: result.readerWriter,
          outputs: {r'$$a|lib/b.txt.copy': 'b'},
        );
      });

      test('builds hidden asset forming a custom public source', () async {
        final result = await testPhases(
          builderFactories,
          [BuilderDefinition('', hideOutput: true)],
          {
            'a|include/a.txt': 'a',
            'a|lib/b.txt': 'b',
            'a|build.yaml': '''
additional_public_assets:
  - include/**
''',
          },
          checkBuildStatus: false,
          buildDirs: {BuildDirectory('web')},
        );

        checkBuild(
          result.buildResult,
          readerWriter: result.readerWriter,
          outputs: {r'$$a|include/a.txt.copy': 'a', r'$$a|lib/b.txt.copy': 'b'},
        );
      });
    });

    group('reading assets outside of the root package', () {
      test('can read public non-lib assets', () async {
        final builder = TestBuilder(
          build: copyFrom(makeAssetId('b|test/foo.bar')),
        );

        await testBuilders(
          [builder],
          {
            'a|lib/a.foo': '',
            'b|test/foo.bar': 'content',
            'b|build.yaml': '''
additional_public_assets:
  - test/**
''',
          },
          // Visible output so it only runs on the root package `a`.
          visibleOutputBuilders: {builder},
          outputs: {r'a|lib/a.foo.copy': 'content'},
          testingBuilderConfig: false,
        );
      });

      test('reading private assets throws InvalidInputException', () {
        final builder = TestBuilder(
          buildExtensions: const {
            '.txt': ['.copy'],
          },
          build: (step, _) {
            final invalidInput = AssetId.parse('b|test/my_test.dart');

            expect(step.canRead(invalidInput), completion(isFalse));
            return expectLater(
              () => step.readAsBytes(invalidInput),
              throwsA(
                isA<InvalidInputException>().having(
                  (e) => e.allowedGlobs,
                  'allowedGlobs',
                  defaultDependencyVisibleAssets,
                ),
              ),
            );
          },
        );

        return testBuilders(
          [builder],
          {'a|lib/foo.txt': "doesn't matter"},
          outputs: {},
        );
      });

      test('canRead doesn\'t throw for invalid inputs or missing packages', () {
        final builder = TestBuilder(
          buildExtensions: const {
            '.txt': ['.copy'],
          },
          build: (step, _) {
            expect(
              step.canRead(AssetId('b', 'test/my_test.dart')),
              completion(isFalse),
            );
            expect(
              step.canRead(AssetId('invalid', 'foo.dart')),
              completion(isFalse),
            );
          },
        );

        return testBuilders(
          [builder],
          {'a|lib/foo.txt': "doesn't matter"},
          outputs: {},
        );
      });
    });

    test(
      'skips builders which would output files in non-root packages',
      () async {
        await testBuilders(
          [testBuilder],
          {'b|lib/b.txt': 'b'},
          // Visible output so it only runs on the root package `a`.
          visibleOutputBuilders: {testBuilder},
          rootPackage: 'a',
          outputs: {},
        );
      },
    );

    group('with `hideOutput: true`', () {
      late BuildPackages buildPackages;

      setUp(() {
        buildPackages = createBuildPackages({
          rootPackage('a', path: 'a/'): ['b'],
          package('b', path: 'a/b/'): [],
        });
      });
      test('can output files in non-root packages', () async {
        await testPhases(
          builderFactories,
          [
            BuilderDefinition(
              '',
              autoApply: AutoApply.allPackages,
              hideOutput: true,
              appliesBuilders: ['a:post_copy_builder'],
            ),
            postCopyABuilderDefinition,
          ],
          {'b|lib/b.txt': 'b'},
          buildPackages: buildPackages,
          outputs: {r'$$b|lib/b.txt.copy': 'b', r'$$b|lib/b.txt.post': 'b'},
        );
      });

      test('handles mixed hidden and non-hidden outputs', () async {
        final result = await testBuilders(
          [
            testBuilder,
            TestBuilder(buildExtensions: appendExtension('.hiddencopy')),
          ],
          {'a|lib/a.txt': 'a'},
          visibleOutputBuilders: {testBuilder},
          outputs: {
            r'a|lib/a.txt.hiddencopy': 'a',
            r'a|lib/a.txt.copy.hiddencopy': 'a',
            r'a|lib/a.txt.copy': 'a',
          },
        );
        // Two of the outputs are under the generated output path.
        expect(
          result.readerWriter.testing.assets.where(
            (a) => a.path.contains('.dart_tool/build/generated'),
          ),
          hasLength(2),
        );
      });

      test('allows reading hidden outputs from another package to create '
          'a non-hidden output', () async {
        final builder1 = TestBuilder();
        final builder2 = TestBuilder(
          buildExtensions: appendExtension('.check_can_read'),
          build: writeCanRead(makeAssetId('b|lib/b.txt.copy')),
        );
        await testBuilders(
          [builder1, builder2],
          {'a|lib/a.txt': 'a', 'b|lib/b.txt': 'b'},
          visibleOutputBuilders: {builder2},
          outputs: {
            r'a|lib/a.txt.copy': 'a',
            r'a|lib/a.txt.copy.check_can_read': 'true',
            r'b|lib/b.txt.copy': 'b',
            r'a|lib/a.txt.check_can_read': 'true',
          },
        );
      });

      test('allows reading hidden outputs from same package to create '
          'a non-hidden output', () async {
        final builder1 = TestBuilder();
        final builder2 = TestBuilder(
          buildExtensions: appendExtension('.check_can_read'),
          build: writeCanRead(makeAssetId('a|lib/a.txt.copy')),
        );
        await testBuilders(
          [builder1, builder2],
          {'a|lib/a.txt': 'a'},
          visibleOutputBuilders: {builder2},
          outputs: {
            r'a|lib/a.txt.copy': 'a',
            r'a|lib/a.txt.copy.check_can_read': 'true',
            r'a|lib/a.txt.check_can_read': 'true',
          },
        );
      });

      test('Will not delete from non-root packages', () async {
        await testPhases(
          builderFactories,
          [
            BuilderDefinition(
              '',
              autoApply: AutoApply.allPackages,
              hideOutput: true,
            ),
          ],
          {
            'b|lib/b.txt': 'b',
            'a|.dart_tool/build/generated/b/lib/b.txt.copy': 'b',
          },
          buildPackages: buildPackages,
          outputs: {r'$$b|lib/b.txt.copy': 'b'},
          onDelete: (AssetId assetId) {
            if (assetId.package != 'a') {
              throw StateError(
                'Should not delete outside of package:a, '
                'tried to delete $assetId',
              );
            }
          },
        );
      });
    });

    test('can read files from external packages', () async {
      final builder = TestBuilder(
        extraWork:
            (buildStep, _) => buildStep.canRead(makeAssetId('b|lib/b.txt')),
      );
      await testBuilders(
        [builder],
        visibleOutputBuilders: {builder},
        {'a|lib/a.txt': 'a', 'b|lib/b.txt': 'b'},
        outputs: {'a|lib/a.txt.copy': 'a'},
      );
    });

    test('can glob files from packages', () async {
      await testBuilders(
        [globBuilder],
        {
          'a|lib/a.globPlaceholder': '',
          'a|lib/a.txt': '',
          'a|lib/b.txt': '',
          'a|web/a.txt': '',
          'b|lib/b.globPlaceholder': '',
          'b|lib/c.txt': '',
          'b|lib/d.txt': '',
          'b|web/b.txt': '',
        },
        outputs: {
          r'a|lib/a.matchingFiles': 'a|lib/a.txt\na|lib/b.txt\na|web/a.txt',
          r'b|lib/b.matchingFiles': 'b|lib/c.txt\nb|lib/d.txt',
        },
      );
    });

    test('can glob files with excludes applied', () async {
      await testBuilders(
        [globBuilder],
        {
          'a|lib/a/1.txt': '',
          'a|lib/a/2.txt': '',
          'a|lib/b/1.txt': '',
          'a|lib/b/2.txt': '',
          'a|lib/test.globPlaceholder': '',
          'a|build.yaml': r'''
targets:
  a:
    sources:
      exclude:
        - lib/a/**
''',
        },
        outputs: {'a|lib/test.matchingFiles': 'a|lib/b/1.txt\na|lib/b/2.txt'},
        testingBuilderConfig: false,
      );
    });

    test('can build on files outside the hardcoded sources', () async {
      await testBuilders(
        [
          TestBuilder(
            buildExtensions: {
              '.txt': ['.txt.copy'],
            },
          ),
        ],
        {
          'a|test_files/a.txt': 'a',
          'a|build.yaml': '''
targets:
  a:
    sources:
      - test_files/**
''',
        },
        outputs: {'a|test_files/a.txt.copy': 'a'},
      );
    });

    test('can\'t read files in .dart_tool', () async {
      expect(
        (await testBuilders(
          [TestBuilder(build: copyFrom(makeAssetId('a|.dart_tool/any_file')))],
          {'a|lib/a.txt': 'a', 'a|.dart_tool/any_file': 'content'},
        )).succeeded,
        false,
      );
    });

    test(
      'Overdeclared outputs are not treated as inputs to later steps',
      () async {
        final builders = [
          TestBuilder(
            buildExtensions: appendExtension('.unexpected'),
            build: (_, _) {},
          ),
          TestBuilder(buildExtensions: appendExtension('.expected')),
          TestBuilder(),
        ];
        await testBuilders(
          builders,
          {'a|lib/a.txt': 'a'},
          outputs: {
            'a|lib/a.txt.copy': 'a',
            'a|lib/a.txt.expected': 'a',
            'a|lib/a.txt.expected.copy': 'a',
          },
        );
      },
    );

    test('can build files from one dir when building another dir', () async {
      await testPhases(
        BuilderFactories({
          '': [(_) => TestBuilder()],
          'b2': [
            (_) => TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.txt'),
              extraWork: (buildStep, _) async {
                // Should not trigger a.txt.copy to be built.
                await buildStep.readAsString(AssetId('a', 'test/a.txt'));
                // Should trigger b.txt.copy to be built.
                await buildStep.readAsString(AssetId('a', 'test/b.txt.copy'));
              },
            ),
          ],
        }),
        [
          BuilderDefinition(
            '',
            hideOutput: true,
            targetBuilderConfigDefaults: const TargetBuilderConfigDefaults(
              generateFor: InputSet(include: ['test/*.txt']),
            ),
          ),
          BuilderDefinition(
            'b2',
            hideOutput: true,
            targetBuilderConfigDefaults: const TargetBuilderConfigDefaults(
              generateFor: InputSet(include: ['web/*.txt']),
            ),
          ),
        ],
        {'a|test/a.txt': 'a', 'a|test/b.txt': 'b', 'a|web/a.txt': 'a'},
        outputs: {r'$$a|web/a.txt.copy': 'a', r'$$a|test/b.txt.copy': 'b'},
        buildDirs: {BuildDirectory('web')},
        verbose: true,
      );
    });

    test(
      'build to source builders are always ran regardless of buildDirs',
      () async {
        await testPhases(
          builderFactories,
          [
            BuilderDefinition(
              '',
              hideOutput: false,
              targetBuilderConfigDefaults: const TargetBuilderConfigDefaults(
                generateFor: InputSet(include: ['**/*.txt']),
              ),
            ),
          ],
          {'a|test/a.txt': 'a', 'a|web/a.txt': 'a'},
          outputs: {r'a|test/a.txt.copy': 'a', r'a|web/a.txt.copy': 'a'},
          buildDirs: {BuildDirectory('web')},
          verbose: true,
        );
      },
    );

    test('can output performance logs', () async {
      final result = await testPhases(
        builderFactories,
        [
          BuilderDefinition(
            'test_builder',
            autoApply: AutoApply.rootPackage,
            isOptional: false,
            hideOutput: false,
          ),
        ],
        {'a|web/a.txt': 'a'},
        outputs: {'a|web/a.txt.copy': 'a'},
        logPerformanceDir: 'perf',
      );
      final logs =
          await result.readerWriter.assetFinder
              .find(Glob('perf/**'), package: 'a')
              .toList();
      expect(logs.length, 1);
      final perf = BuildPerformance.fromJson(
        jsonDecode(await result.readerWriter.readAsString(logs.first))
            as Map<String, dynamic>,
      );
      expect(perf.phases.length, 1);
      expect(perf.phases.first.builderKeys, equals(['test_builder']));
    });

    group('buildFilters', () {
      final buildPackagesWithDep = createBuildPackages({
        package('b'): [],
        rootPackage('a'): ['b'],
      });

      test('explicit files by uri and path', () async {
        await testPhases(
          builderFactories,
          [
            BuilderDefinition(
              '',
              autoApply: AutoApply.allPackages,
              targetBuilderConfigDefaults: const TargetBuilderConfigDefaults(
                generateFor: InputSet(include: ['**/*.txt']),
              ),
            ),
          ],
          {
            'a|lib/a.txt': '',
            'a|web/a.txt': '',
            'a|web/a0.txt': '',
            'b|lib/b.txt': '',
            'b|lib/b0.txt': '',
          },
          outputs: {
            r'$$a|lib/a.txt.copy': '',
            r'$$a|web/a.txt.copy': '',
            r'$$b|lib/b.txt.copy': '',
          },
          buildFilters: {
            BuildFilter.fromArg('web/a.txt.copy', 'a'),
            BuildFilter.fromArg('package:a/a.txt.copy', 'a'),
            BuildFilter.fromArg('package:b/b.txt.copy', 'a'),
          },
          verbose: true,
          buildPackages: buildPackagesWithDep,
        );
      });

      test('with package globs', () async {
        await testPhases(
          builderFactories,
          [
            BuilderDefinition(
              '',
              autoApply: AutoApply.allPackages,
              targetBuilderConfigDefaults: const TargetBuilderConfigDefaults(
                generateFor: InputSet(include: ['**/*.txt']),
              ),
            ),
          ],
          {'a|lib/a.txt': '', 'b|lib/a.txt': ''},
          outputs: {r'$$a|lib/a.txt.copy': '', r'$$b|lib/a.txt.copy': ''},
          buildFilters: {BuildFilter.fromArg('package:*/a.txt.copy', 'a')},
          verbose: true,
          buildPackages: buildPackagesWithDep,
        );
      });

      test('with path globs', () async {
        await testPhases(
          builderFactories,
          [
            BuilderDefinition(
              '',
              autoApply: AutoApply.allPackages,
              targetBuilderConfigDefaults: const TargetBuilderConfigDefaults(
                generateFor: InputSet(include: ['**/*.txt']),
              ),
            ),
          ],
          {
            'a|lib/a.txt': '',
            'a|lib/a0.txt': '',
            'a|web/a.txt': '',
            'a|web/a1.txt': '',
            'b|lib/b.txt': '',
            'b|lib/b2.txt': '',
          },
          outputs: {
            r'$$a|lib/a0.txt.copy': '',
            r'$$a|web/a1.txt.copy': '',
            r'$$b|lib/b2.txt.copy': '',
          },
          buildFilters: {
            BuildFilter.fromArg('package:a/*0.txt.copy', 'a'),
            BuildFilter.fromArg('web/*1.txt.copy', 'a'),
            BuildFilter.fromArg('package:b/*2.txt.copy', 'a'),
          },
          verbose: true,
          buildPackages: buildPackagesWithDep,
        );
      });

      test('with package and path globs', () async {
        await testPhases(
          builderFactories,
          [
            BuilderDefinition(
              '',
              autoApply: AutoApply.allPackages,
              targetBuilderConfigDefaults: const TargetBuilderConfigDefaults(
                generateFor: InputSet(include: ['**/*.txt']),
              ),
            ),
          ],
          {'a|lib/a.txt': '', 'b|lib/b.txt': ''},
          outputs: {r'$$a|lib/a.txt.copy': '', r'$$b|lib/b.txt.copy': ''},
          buildFilters: {BuildFilter.fromArg('package:*/*.txt.copy', 'a')},
          verbose: true,
          buildPackages: buildPackagesWithDep,
        );
      });
    });
  });

  test('tracks dependency graph in a asset_graph.json file', () async {
    final result = await testPhases(
      builderFactories,
      [requiresPostProcessBuilderDefinition, postCopyABuilderDefinition],
      {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
      outputs: {
        'a|web/a.txt.copy': 'a',
        'a|lib/b.txt.copy': 'b',
        r'$$a|web/a.txt.post': 'a',
        r'$$a|lib/b.txt.post': 'b',
      },
    );

    final graphId = makeAssetId('a|$assetGraphPath');
    expect(result.readerWriter.testing.exists(graphId), isTrue);
    final cachedGraph =
        AssetGraph.deserialize(result.readerWriter.testing.readBytes(graphId))!;

    final expectedGraph = await AssetGraph.build(
      BuildPhases([]),
      <AssetId>{},
      createBuildPackages({rootPackage('a'): []}),
      result.readerWriter,
    );

    // Source nodes
    final aId = AssetId.parse('a|web/a.txt');
    var aSourceNode = AssetNode.source(aId, digest: computeDigest(aId, 'a'));
    final bId = AssetId.parse('a|lib/b.txt');
    var bSourceNode = AssetNode.source(bId, digest: computeDigest(bId, 'b'));

    // Regular generated asset nodes.
    final aCopyId = AssetId.parse('a|web/a.txt.copy');
    final aCopyNode = AssetNode.generated(
      aCopyId,
      phaseNumber: 0,
      primaryInput: makeAssetId('a|web/a.txt'),
      result: true,
      digest: computeDigest(aCopyId, 'a'),
      inputs: [makeAssetId('a|web/a.txt')],
      isHidden: false,
    );
    aSourceNode = aSourceNode.rebuild(
      (b) => b..primaryOutputs.add(aCopyNode.id),
    );

    final bCopyId = makeAssetId('a|lib/b.txt.copy'); //;
    final bCopyNode = AssetNode.generated(
      bCopyId,
      phaseNumber: 0,
      primaryInput: makeAssetId('a|lib/b.txt'),
      result: true,
      digest: computeDigest(bCopyId, 'b'),
      inputs: [makeAssetId('a|lib/b.txt')],
      isHidden: false,
    );
    bSourceNode = bSourceNode.rebuild(
      (b) => b..primaryOutputs.add(bCopyNode.id),
    );

    // Post build generates asset nodes.
    final aPostProcessBuildStepId = PostProcessBuildStepId(
      input: aSourceNode.id,
      actionNumber: 0,
    );
    final bPostProcessBuildStepId = PostProcessBuildStepId(
      input: bSourceNode.id,
      actionNumber: 0,
    );

    final aPostCopyNode = AssetNode.generated(
      makeAssetId('a|web/a.txt.post'),
      phaseNumber: 1,
      primaryInput: makeAssetId('a|web/a.txt'),
      result: true,
      digest: computeDigest(makeAssetId(r'$$a|web/a.txt.post'), 'a'),
      inputs: [makeAssetId('a|web/a.txt')],
      isHidden: true,
    );
    // Note we don't expect this node to get added to the builder options node
    // outputs.
    aSourceNode = aSourceNode.rebuild(
      (b) => b..primaryOutputs.add(aPostCopyNode.id),
    );

    final bPostCopyNode = AssetNode.generated(
      makeAssetId('a|lib/b.txt.post'),
      phaseNumber: 1,
      primaryInput: makeAssetId('a|lib/b.txt'),
      result: true,
      digest: computeDigest(makeAssetId(r'$$a|lib/b.txt.post'), 'b'),
      inputs: [makeAssetId('a|lib/b.txt')],
      isHidden: true,
    );
    // Note we don't expect this node to get added to the builder options node
    // outputs.
    bSourceNode = bSourceNode.rebuild(
      (b) => b..primaryOutputs.add(bPostCopyNode.id),
    );

    expectedGraph
      ..add(aSourceNode)
      ..add(bSourceNode)
      ..add(aCopyNode)
      ..add(bCopyNode)
      ..add(aPostCopyNode)
      ..add(bPostCopyNode)
      ..updatePostProcessBuildStep(
        aPostProcessBuildStepId,
        outputs: {aPostCopyNode.id},
      )
      ..updatePostProcessBuildStep(
        bPostProcessBuildStepId,
        outputs: {bPostCopyNode.id},
      );

    expect(cachedGraph, equalsAssetGraph(expectedGraph));
    expect(
      cachedGraph.allPostProcessBuildStepOutputs,
      expectedGraph.allPostProcessBuildStepOutputs,
    );
  });

  test(
    "builders reading their output don't cause self-referential nodes",
    () async {
      final result = await testBuilders(
        [
          TestBuilder(
            build: (step, _) async {
              final output = step.inputId.addExtension('.out');
              await step.writeAsString(output, 'a');
              await step.readAsString(output);
            },
            buildExtensions: appendExtension('.out', from: '.txt'),
          ),
        ],
        {'a|lib/a.txt': 'a'},
        outputs: {'a|lib/a.txt.out': 'a'},
      );

      final graphId = makeAssetId('a|$assetGraphPath');
      final cachedGraph =
          AssetGraph.deserialize(
            result.readerWriter.testing.readBytes(graphId),
          )!;
      final outputId = AssetId('a', 'lib/a.txt.out');

      final outputNode = cachedGraph.get(outputId)!;
      expect(outputNode.generatedNodeState!.inputs, isNot(contains(outputId)));
    },
  );

  test(
    'outputs from previous full builds shouldn\'t be inputs to later ones',
    () async {
      final inputs = <String, String>{'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'};
      final outputs = <String, String>{
        'a|web/a.txt.copy': 'a',
        'a|lib/b.txt.copy': 'b',
      };
      // First run, nothing special.
      var result = await testBuilders(
        [TestBuilder()],
        inputs,
        outputs: outputs,
      );
      // Second run, only output should be the asset graph.
      for (final id in result.readerWriter.testing.assets) {
        inputs[id.toString()] = await result.readerWriter.readAsString(id);
      }
      result = await testBuilders([TestBuilder()], inputs);
      expect(
        result.readerWriter.testing.assetsWritten.single.toString(),
        contains('asset_graph.json'),
      );
    },
  );

  test('can recover from a deleted asset_graph.json cache', () async {
    final inputs = <String, String>{'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'};
    final outputs = <String, String>{
      'a|web/a.txt.copy': 'a',
      'a|lib/b.txt.copy': 'b',
    };
    // First run, nothing special.
    final result = await testBuilders(
      [TestBuilder()],
      inputs,
      outputs: outputs,
    );

    // Delete the `asset_graph.json` file!
    final outputId = makeAssetId('a|$assetGraphPath');
    await (result.readerWriter as ReaderWriter).delete(outputId);

    // Second run, should have no extra outputs.
    await testBuilders(
      [TestBuilder()],
      inputs,
      outputs: outputs,
      readerWriter: result.readerWriter,
    );
  });

  group('incremental builds with cached graph', () {
    group('reportUnusedAssets', () {
      test('removes input dependencies', () async {
        final builderFactories = BuilderFactories({
          '': [
            (_) => TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.txt'),
              // Add two extra deps, but remove one since we decided not to use
              // it.
              build: (BuildStep buildStep, _) async {
                final usedId = buildStep.inputId.addExtension('.used');

                final content =
                    await buildStep.readAsString(buildStep.inputId) +
                    await buildStep.readAsString(usedId);
                await buildStep.writeAsString(
                  buildStep.inputId.addExtension('.copy'),
                  content,
                );

                final unusedId = buildStep.inputId.addExtension('.unused');
                await buildStep.canRead(unusedId);
                buildStep.reportUnusedAssets([unusedId]);
              },
            ),
          ],
        });
        final builderDefinitions = [BuilderDefinition('', hideOutput: false)];

        // Initial build.
        final result = await testPhases(
          builderFactories,
          builderDefinitions,
          {
            'a|lib/a.txt': 'a',
            'a|lib/a.txt.used': 'b',
            'a|lib/a.txt.unused': 'c',
          },
          outputs: {'a|lib/a.txt.copy': 'ab'},
        );

        // Followup build with modified unused inputs should have no outputs.
        await testPhases(
          builderFactories,
          builderDefinitions,
          {
            'a|lib/a.txt': 'a',
            'a|lib/a.txt.used': 'b',
            'a|lib/a.txt.unused': 'd', // changed the content of this one
            'a|lib/a.txt.copy': 'ab',
          },
          outputs: {},
          resumeFrom: result,
        );

        // And now modify a real input.
        await testPhases(
          builderFactories,
          builderDefinitions,
          {
            'a|lib/a.txt': 'a',
            'a|lib/a.txt.used': 'e',
            'a|lib/a.txt.unused': 'd',
            'a|lib/a.txt.copy': 'ab',
          },
          outputs: {'a|lib/a.txt.copy': 'ae'},
          resumeFrom: result,
        );

        // Finally modify the primary input.
        await testPhases(
          builderFactories,
          builderDefinitions,
          {
            'a|lib/a.txt': 'f',
            'a|lib/a.txt.used': 'e',
            'a|lib/a.txt.unused': 'd',
            'a|lib/a.txt.copy': 'ae',
          },
          outputs: {'a|lib/a.txt.copy': 'fe'},
          resumeFrom: result,
        );
      });

      test('allows marking the primary input as unused', () async {
        final builderFactories = BuilderFactories({
          '': [
            (_) => TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.txt'),
              // Add two extra deps, but remove one since we decided not to use
              // it.
              extraWork: (BuildStep buildStep, _) async {
                buildStep.reportUnusedAssets([buildStep.inputId]);
                final usedId = buildStep.inputId.addExtension('.used');
                await buildStep.canRead(usedId);
              },
            ),
          ],
        });
        final builderDefinitions = [BuilderDefinition('', hideOutput: false)];

        // Initial build.
        final result = await testPhases(
          builderFactories,
          builderDefinitions,
          {'a|lib/a.txt': 'a', 'a|lib/a.txt.used': ''},
          outputs: {'a|lib/a.txt.copy': 'a'},
        );

        // Followup build with modified primary input should have no outputs.
        await testPhases(
          builderFactories,
          builderDefinitions,
          {'a|lib/a.txt': 'b', 'a|lib/a.txt.used': '', 'a|lib/a.txt.copy': 'a'},
          outputs: {},
          resumeFrom: result,
        );

        // But modifying other inputs still causes a rebuild.
        await testPhases(
          builderFactories,
          builderDefinitions,
          {
            'a|lib/a.txt': 'b',
            'a|lib/a.txt.used': 'b',
            'a|lib/a.txt.copy': 'a',
          },
          outputs: {'a|lib/a.txt.copy': 'b'},
          resumeFrom: result,
        );
      });

      test(
        'marking the primary input as unused still tracks if it is deleted',
        () async {
          final builderFactories = BuilderFactories({
            '': [
              (_) => TestBuilder(
                buildExtensions: appendExtension('.copy', from: '.txt'),
                // Add two extra deps, but remove one since we decided not to
                // use it.
                extraWork: (BuildStep buildStep, _) async {
                  buildStep.reportUnusedAssets([buildStep.inputId]);
                },
              ),
            ],
          });
          final builderDefinitions = [BuilderDefinition('', hideOutput: false)];
          // Initial build.
          final result = await testPhases(
            builderFactories,
            builderDefinitions,
            {'a|lib/a.txt': 'a'},
            outputs: {'a|lib/a.txt.copy': 'a'},
          );

          // Delete the primary input, the output shoud still be deleted
          result.readerWriter.testing.delete(AssetId('a', 'lib/a.txt'));
          await testPhases(
            builderFactories,
            builderDefinitions,
            {'a|lib/a.txt.copy': 'a'},
            outputs: {},
            resumeFrom: result,
          );

          final graph =
              AssetGraph.deserialize(
                result.readerWriter.testing.readBytes(
                  makeAssetId('a|$assetGraphPath'),
                ),
              )!;
          expect(
            graph.get(makeAssetId('a|lib/a.txt.copy'))!.type,
            NodeType.missingSource,
          );
        },
      );
    });

    test('graph/file system get cleaned up for deleted inputs', () async {
      final builderFactories = BuilderFactories({
        '': [(_) => TestBuilder()],
        'b2': [
          (_) => TestBuilder(
            buildExtensions: {
              '.txt': ['.txt.clone'],
            },
          ),
        ],
      });
      final builderDefinitions = [
        BuilderDefinition('', hideOutput: false),
        BuilderDefinition('b2', hideOutput: false),
      ];

      // Initial build.
      final result = await testPhases(
        builderFactories,
        builderDefinitions,
        {'a|lib/a.txt': 'a'},
        outputs: {'a|lib/a.txt.copy': 'a', 'a|lib/a.txt.clone': 'a'},
      );

      // Followup build with deleted input + cached graph.
      result.readerWriter.testing.delete(AssetId('a', 'lib/a.txt'));
      await testPhases(
        builderFactories,
        builderDefinitions,
        {'a|lib/a.txt.copy': 'a', 'a|lib/a.txt.clone': 'a'},
        outputs: {},
        resumeFrom: result,
      );

      /// Should be deleted using the writer, and converted to missingSource.
      final newGraph =
          AssetGraph.deserialize(
            result.readerWriter.testing.readBytes(
              makeAssetId('a|$assetGraphPath'),
            ),
          )!;
      final aNodeId = makeAssetId('a|lib/a.txt');
      final aCopyNodeId = makeAssetId('a|lib/a.txt.copy');
      final aCloneNodeId = makeAssetId('a|lib/a.txt.copy.clone');
      expect(newGraph.get(aNodeId)!.type, NodeType.missingSource);
      expect(newGraph.get(aCopyNodeId)!.type, NodeType.missingSource);
      expect(newGraph.contains(aCloneNodeId), isFalse);
      expect(result.readerWriter.testing.exists(aNodeId), isFalse);
      expect(result.readerWriter.testing.exists(aCopyNodeId), isFalse);
      expect(result.readerWriter.testing.exists(aCloneNodeId), isFalse);
    });

    test('no outputs if no changed sources', () async {
      final builderDefinitions = [BuilderDefinition('', hideOutput: false)];
      // Initial build.
      final result = await testPhases(
        builderFactories,
        builderDefinitions,
        {'a|web/a.txt': 'a'},
        outputs: {'a|web/a.txt.copy': 'a'},
      );

      // Followup build with same sources + cached graph.
      await testPhases(
        builderFactories,
        builderDefinitions,
        {},
        outputs: {},
        resumeFrom: result,
      );
    });

    test('no outputs if no changed sources using `hideOutput: true`', () async {
      final builderDefinitions = [
        BuilderDefinition(
          '',
          autoApply: AutoApply.rootPackage,
          hideOutput: true,
        ),
      ];

      // Initial build.
      final result = await testPhases(
        builderFactories,
        builderDefinitions,
        {'a|web/a.txt': 'a'},
        // Note that `testBuilders` converts generated cache dir paths to the
        // original ones for matching.
        outputs: {r'$$a|web/a.txt.copy': 'a'},
      );

      // Followup build with same sources + cached graph.
      await testPhases(
        builderFactories,
        builderDefinitions,
        {},
        outputs: {},
        resumeFrom: result,
      );
    });

    test('inputs/outputs are updated if they change', () async {
      final builderDefinitions = [BuilderDefinition('', hideOutput: false)];
      // Initial build.
      final result = await testPhases(
        BuilderFactories({
          '': [
            (_) => TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.a'),
              build: copyFrom(makeAssetId('a|lib/file.b')),
            ),
          ],
        }),
        builderDefinitions,
        {'a|lib/file.a': 'a', 'a|lib/file.b': 'b', 'a|lib/file.c': 'c'},
        outputs: {'a|lib/file.a.copy': 'b'},
      );

      // Followup build with same sources + cached graph, but configure the
      // builder to read a different file.
      await testPhases(
        BuilderFactories({
          '': [
            (_) => TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.a'),
              build: copyFrom(makeAssetId('a|lib/file.c')),
            ),
          ],
        }),
        builderDefinitions,
        {
          'a|lib/file.a': 'a',
          'a|lib/file.a.copy': 'b',
          // Hack to get the file to rebuild, we are being bad by changing the
          // builder but pretending its the same.
          'a|lib/file.b': 'b2',
          'a|lib/file.c': 'c',
        },
        outputs: {'a|lib/file.a.copy': 'c'},
        resumeFrom: result,
      );

      // Read cached graph and validate.
      final graph =
          AssetGraph.deserialize(
            result.readerWriter.testing.readBytes(
              makeAssetId('a|$assetGraphPath'),
            ),
          )!;
      final outputNode = graph.get(makeAssetId('a|lib/file.a.copy'))!;
      final fileANode = graph.get(makeAssetId('a|lib/file.a'))!;
      final fileBNode = graph.get(makeAssetId('a|lib/file.b'))!;
      final fileCNode = graph.get(makeAssetId('a|lib/file.c'))!;
      expect(
        outputNode.generatedNodeState!.inputs,
        unorderedEquals([fileANode.id, fileCNode.id]),
      );
      final computedOutputs = graph.computeOutputs();
      expect(computedOutputs[fileANode.id]!, contains(outputNode.id));
      expect(computedOutputs[fileBNode.id] ?? const <AssetId>{}, isEmpty);
      expect(computedOutputs[fileCNode.id]!, unorderedEquals([outputNode.id]));
    });

    test('Ouputs aren\'t rebuilt if their inputs didn\'t change', () async {
      final builderFactories = BuilderFactories({
        '': [
          (_) => TestBuilder(
            buildExtensions: appendExtension('.copy', from: '.a'),
            build: copyFrom(makeAssetId('a|lib/file.b')),
          ),
        ],
        'b2': [
          (_) => TestBuilder(
            buildExtensions: appendExtension('.copy', from: '.a.copy'),
          ),
        ],
      });
      final builderDefinitions = [
        BuilderDefinition(''),
        BuilderDefinition('b2'),
      ];

      // Initial build.
      final result = await testPhases(
        builderFactories,
        builderDefinitions,
        {'a|lib/file.a': 'a', 'a|lib/file.b': 'b'},
        outputs: {'a|lib/file.a.copy': 'b', 'a|lib/file.a.copy.copy': 'b'},
      );

      // Modify the primary input of `file.a.copy`, but its output doesn't
      // change so `file.a.copy.copy` shouldn't be rebuilt.
      await testPhases(
        builderFactories,
        builderDefinitions,
        {
          'a|lib/file.a': 'a2',
          'a|lib/file.b': 'b',
          'a|lib/file.a.copy': 'b',
          'a|lib/file.a.copy.copy': 'b',
        },
        outputs: {'a|lib/file.a.copy': 'b'},
        resumeFrom: result,
      );
    });

    test('no implicit dependency on primary input contents', () async {
      final builderFactories = BuilderFactories({
        '': [(_) => SiblingCopyBuilder()],
      });
      final builderDefinitions = [BuilderDefinition('', hideOutput: false)];

      // Initial build.
      var result = await testPhases(
        builderFactories,
        builderDefinitions,
        {'a|web/a.txt': 'a', 'a|web/a.txt.sibling': 'sibling'},
        outputs: {'a|web/a.txt.new': 'sibling'},
      );

      // Followup build with cached graph and a changed primary input, but the
      // actual file that was read has not changed.
      result = await testPhases(
        builderFactories,
        builderDefinitions,
        {
          'a|web/a.txt': 'b',
          'a|web/a.txt.sibling': 'sibling',
          'a|web/a.txt.new': 'sibling',
        },
        outputs: {},
        resumeFrom: result,
      );

      // And now try modifying the sibling to make sure that still works.
      await testPhases(
        builderFactories,
        builderDefinitions,
        {
          'a|web/a.txt': 'b',
          'a|web/a.txt.sibling': 'new!',
          'a|web/a.txt.new': 'sibling',
        },
        outputs: {'a|web/a.txt.new': 'new!'},
        resumeFrom: result,
      );
    });
  });

  group('regression tests', () {
    test('a failed output on a primary input which is not output in later '
        'builds', () async {
      final builderFactories = BuilderFactories({
        '': [
          (_) => TestBuilder(
            buildExtensions: replaceExtension('.source', '.g1'),
            build: (buildStep, _) async {
              final content = await buildStep.readAsString(buildStep.inputId);
              if (content == 'true') {
                await buildStep.writeAsString(
                  buildStep.inputId.changeExtension('.g1'),
                  '',
                );
              }
            },
          ),
        ],
        'b2': [
          (_) => TestBuilder(
            buildExtensions: replaceExtension('.g1', '.g2'),
            build: (buildStep, _) {
              throw StateError('Fails always');
            },
          ),
        ],
      });
      final builderDefinitions = [
        BuilderDefinition(''),
        BuilderDefinition('b2'),
      ];
      final result = await testPhases(builderFactories, builderDefinitions, {
        'a|lib/a.source': 'true',
      }, status: BuildStatus.failure);

      await testPhases(
        builderFactories,
        builderDefinitions,
        {'a|lib/a.source': 'false'},
        outputs: {},
        resumeFrom: result,
      );
    });

    test('the entrypoint cannot be read by a builder', () async {
      final builders = [
        TestBuilder(
          buildExtensions: replaceExtension('.txt', '.hasEntrypoint'),
          build: (buildStep, _) async {
            final hasEntrypoint = await buildStep
                .findAssets(Glob('**'))
                .contains(makeAssetId('a|$entrypointScriptPath'));
            await buildStep.writeAsString(
              buildStep.inputId.changeExtension('.hasEntrypoint'),
              '$hasEntrypoint',
            );
          },
        ),
      ];
      await testBuilders(
        builders,
        {'a|lib/a.txt': 'a', 'a|$entrypointScriptPath': 'some build script'},
        outputs: {'a|lib/a.hasEntrypoint': 'false'},
      );
    });

    test('primary outputs are reran when failures are fixed', () async {
      final builderFactories = BuilderFactories({
        '': [
          (_) => TestBuilder(
            buildExtensions: replaceExtension('.source', '.g1'),
            build: (buildStep, _) async {
              final content = await buildStep.readAsString(buildStep.inputId);
              if (content == 'true') {
                throw StateError('Failed!!!');
              } else {
                await buildStep.writeAsString(
                  buildStep.inputId.changeExtension('.g1'),
                  '',
                );
              }
            },
          ),
        ],
        'b2': [
          (_) => TestBuilder(
            buildExtensions: replaceExtension('.g1', '.g2'),
            build: (buildStep, _) async {
              await buildStep.writeAsString(
                buildStep.inputId.changeExtension('.g2'),
                '',
              );
            },
          ),
        ],
        'b3': [
          (_) => TestBuilder(
            buildExtensions: replaceExtension('.g2', '.g3'),
            build: (buildStep, _) async {
              await buildStep.writeAsString(
                buildStep.inputId.changeExtension('.g3'),
                '',
              );
            },
          ),
        ],
      });
      final builderDefinitions = [
        BuilderDefinition('', isOptional: true),
        BuilderDefinition('b2', isOptional: true),
        BuilderDefinition('b3'),
      ];
      var result = await testPhases(builderFactories, builderDefinitions, {
        'a|web/a.source': 'true',
      }, status: BuildStatus.failure);

      result = await testPhases(
        builderFactories,
        builderDefinitions,
        {'a|web/a.source': 'false'},
        outputs: {'a|web/a.g1': '', 'a|web/a.g2': '', 'a|web/a.g3': ''},
        resumeFrom: result,
      );

      // Make sure if we mark the original node as a failure again, that we
      // also mark all its primary outputs as failures.
      await testPhases(
        builderFactories,
        builderDefinitions,
        {'a|web/a.source': 'true'},
        outputs: {},
        status: BuildStatus.failure,
        resumeFrom: result,
      );

      final finalGraph =
          AssetGraph.deserialize(
            result.readerWriter.testing.readBytes(AssetId('a', assetGraphPath)),
          )!;

      expect(
        finalGraph.get(AssetId('a', 'web/a.g1'))!.generatedNodeState!.result,
        isFalse,
      );
      expect(
        finalGraph.get(AssetId('a', 'web/a.g2'))!.generatedNodeState!.result,
        isFalse,
      );
      expect(
        finalGraph.get(AssetId('a', 'web/a.g3'))!.generatedNodeState!.result,
        isFalse,
      );
    });

    test('a glob should not be an output of an anchor node', () async {
      // https://github.com/dart-lang/build/issues/2017
      final builderFactories = BuilderFactories(
        {
          '': [
            (_) => TestBuilder(
              build: (buildStep, _) {
                buildStep.findAssets(Glob('**'));
              },
            ),
          ],
        },
        postProcessBuilderFactories: {
          'a|copy_builder': (_) => CopyingPostProcessBuilder(),
        },
      );
      final builderDefinitions = [
        BuilderDefinition(
          '',
          hideOutput: false,
          appliesBuilders: ['a|copy_builder'],
        ),
        PostProcessBuilderDefinition('a|copy_builder'),
      ];

      // A build does not crash in `_cleanUpStaleOutputs`
      await testPhases(builderFactories, builderDefinitions, {
        'a|lib/a.txt': 'a',
      });
    });

    test('can have assets ending in a dot', () async {
      final builders = [
        TestBuilder(
          buildExtensions: {
            '': ['copy'],
          },
          build: (step, _) async {
            await step.writeAsString(step.allowedOutputs.single, 'out');
          },
        ),
      ];
      await testBuilders(
        builders,
        {'a|lib/a.': 'a'},
        outputs: {'a|lib/a.copy': 'out'},
      );
    });
  });
}

/// A builder that never actually reads its primary input, but copies from a
/// sibling file instead.
class SiblingCopyBuilder extends Builder {
  @override
  final buildExtensions = {
    '.txt': ['.txt.new'],
  };

  @override
  Future build(BuildStep buildStep) async {
    final sibling = buildStep.inputId.addExtension('.sibling');
    await buildStep.writeAsString(
      buildStep.inputId.addExtension('.new'),
      await buildStep.readAsString(sibling),
    );
  }
}
