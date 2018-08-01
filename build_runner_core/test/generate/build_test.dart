// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner_core/src/asset_graph/graph.dart';
import 'package:build_runner_core/src/asset_graph/node.dart';

import 'package:_test_common/build_configs.dart';
import 'package:_test_common/common.dart';
import 'package:_test_common/package_graphs.dart';

void main() {
  /// Basic phases/phase groups which get used in many tests
  final testBuilder =
      new TestBuilder(buildExtensions: appendExtension('.copy', from: '.txt'));
  final copyABuilderApplication = applyToRoot(testBuilder);
  final requiresPostProcessBuilderApplication = apply(
      'test_builder', [(_) => testBuilder], toRoot(),
      appliesBuilders: ['a|post_copy_builder'], hideOutput: false);
  final postCopyABuilderApplication = applyPostProcess(
      'a|post_copy_builder',
      (options) => new CopyingPostProcessBuilder(
          outputExtension: options.config['extension'] as String ?? '.post'));
  final globBuilder = new GlobbingBuilder(new Glob('**.txt'));
  final defaultBuilderOptions = const BuilderOptions(const {});
  final placeholders =
      placeholderIdsFor(buildPackageGraph({rootPackage('a'): []}));

  group('build', () {
    test('can log within a buildFactory', () async {
      await testBuilders(
        [
          apply(
              '',
              [
                (_) {
                  log.info('I can log!');
                  return new TestBuilder(
                      buildExtensions: appendExtension('.1'));
                }
              ],
              toRoot(),
              isOptional: true,
              hideOutput: false),
        ],
        {'a|web/a.txt': 'a'},
      );
    });

    test('Builder factories are only invoked once per application', () async {
      var invokedCount = 0;
      final packageGraph = buildPackageGraph({
        rootPackage('a'): ['b'],
        package('b'): []
      });
      await testBuilders([
        apply(
            '',
            [
              (_) {
                invokedCount += 1;
                return new TestBuilder();
              }
            ],
            toAllPackages(),
            isOptional: false,
            hideOutput: true),
      ], {}, packageGraph: packageGraph);

      // Once per package, including the SDK.
      expect(invokedCount, 3);
    });

    test('throws an error if the builderFactory fails', () async {
      expect(
          () async => await testBuilders(
                [
                  apply(
                      '',
                      [
                        (_) {
                          throw 'some error';
                        }
                      ],
                      toRoot(),
                      isOptional: true,
                      hideOutput: false),
                ],
                {'a|web/a.txt': 'a'},
              ),
          throwsA(new TypeMatcher<CannotBuildException>()));
    });

    test('runs a max of 16 concurrent actions per phase', () async {
      var assets = <String, String>{};
      for (var i = 0; i < buildPhasePoolSize * 2; i++) {
        assets['a|web/$i.txt'] = '$i';
      }
      var concurrentCount = 0;
      var maxConcurrentCount = 0;
      await testBuilders(
          [
            apply(
                '',
                [
                  (_) {
                    return new TestBuilder(build: (_, __) async {
                      concurrentCount += 1;
                      maxConcurrentCount =
                          max(concurrentCount, maxConcurrentCount);
                      await new Future.delayed(new Duration(milliseconds: 100));
                      concurrentCount -= 1;
                    });
                  }
                ],
                toRoot(),
                isOptional: false,
                hideOutput: false),
          ],
          assets,
          outputs: {});
      expect(maxConcurrentCount, buildPhasePoolSize);
    });

    group('with root package inputs', () {
      test('one phase, one builder, one-to-one outputs', () async {
        await testBuilders(
            [copyABuilderApplication], {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
            outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'});
      });

      test('with a PostProcessBuilder', () async {
        await testBuilders([
          requiresPostProcessBuilderApplication,
          postCopyABuilderApplication,
        ], {
          'a|web/a.txt': 'a',
          'a|lib/b.txt': 'b',
        }, outputs: {
          'a|web/a.txt.copy': 'a',
          'a|lib/b.txt.copy': 'b',
          r'$$a|web/a.txt.post': 'a',
          r'$$a|lib/b.txt.post': 'b',
        });
      });

      test('with placeholder as input', () async {
        await testBuilders([
          applyToRoot(new PlaceholderBuilder({'placeholder.txt': 'sometext'}))
        ], {}, outputs: {
          'a|lib/placeholder.txt': 'sometext'
        });
      });

      test('one phase, one builder, one-to-many outputs', () async {
        await testBuilders([
          applyToRoot(new TestBuilder(
              buildExtensions: appendExtension('.copy', numCopies: 2)))
        ], {
          'a|web/a.txt': 'a',
          'a|lib/b.txt': 'b',
        }, outputs: {
          'a|web/a.txt.copy.0': 'a',
          'a|web/a.txt.copy.1': 'a',
          'a|lib/b.txt.copy.0': 'b',
          'a|lib/b.txt.copy.1': 'b',
        });
      });

      test('optional build actions don\'t run if their outputs aren\'t read',
          () async {
        await testBuilders([
          apply(
              '',
              [(_) => new TestBuilder(buildExtensions: appendExtension('.1'))],
              toRoot(),
              isOptional: true),
          apply(
              'a|only_on_1',
              [
                (_) => new TestBuilder(
                    buildExtensions: appendExtension('.copy', from: '.1'))
              ],
              toRoot(),
              isOptional: true),
        ], {
          'a|lib/a.txt': 'a'
        }, outputs: {});
      });

      test('optional build actions do run if their outputs are read', () async {
        await testBuilders([
          apply(
              '',
              [(_) => new TestBuilder(buildExtensions: appendExtension('.1'))],
              toRoot(),
              isOptional: true,
              hideOutput: false),
          apply(
              '',
              [
                (_) => new TestBuilder(
                    buildExtensions: replaceExtension('.1', '.2'))
              ],
              toRoot(),
              isOptional: true,
              hideOutput: false),
          apply(
              '',
              [
                (_) => new TestBuilder(
                    buildExtensions: replaceExtension('.2', '.3'))
              ],
              toRoot(),
              hideOutput: false),
        ], {
          'a|web/a.txt': 'a'
        }, outputs: {
          'a|web/a.txt.1': 'a',
          'a|web/a.txt.2': 'a',
          'a|web/a.txt.3': 'a',
        });
      });

      test('multiple mixed build actions with custom build config', () async {
        var builders = [
          copyABuilderApplication,
          apply(
              'a|clone_txt',
              [
                (_) =>
                    new TestBuilder(buildExtensions: appendExtension('.clone'))
              ],
              toRoot(),
              isOptional: true,
              hideOutput: false,
              appliesBuilders: ['a|post_copy_builder']),
          apply(
              'a|copy_web_clones',
              [
                (_) => new TestBuilder(
                    buildExtensions: appendExtension('.copy', numCopies: 2))
              ],
              toRoot(),
              hideOutput: false),
          postCopyABuilderApplication,
        ];
        var buildConfigs = parseBuildConfigs({
          'a': {
            'targets': {
              'a': {
                'sources': ['**'],
                'builders': {
                  'a|clone_txt': {
                    'generate_for': ['**/*.txt']
                  },
                  'a|copy_web_clones': {
                    'generate_for': ['web/*.txt.clone']
                  },
                  'a|post_copy_builder': {
                    'options': {'extension': '.custom.post'},
                    'generate_for': ['web/*.txt']
                  }
                }
              }
            }
          }
        });
        await testBuilders(
            builders,
            {
              'a|web/a.txt': 'a',
              'a|lib/b.txt': 'b',
            },
            overrideBuildConfig: buildConfigs,
            outputs: {
              'a|web/a.txt.copy': 'a',
              'a|web/a.txt.clone': 'a',
              'a|lib/b.txt.copy': 'b',
              // No b.txt.clone since nothing else read it and its optional.
              'a|web/a.txt.clone.copy.0': 'a',
              'a|web/a.txt.clone.copy.1': 'a',
              r'$$a|web/a.txt.custom.post': 'a',
            });
      });

      test(
          'allows running on generated inputs that do not match target '
          'source globx', () async {
        var builders = [
          applyToRoot(new TestBuilder(
              buildExtensions: appendExtension('.1', from: '.txt'))),
          applyToRoot(new TestBuilder(
              buildExtensions: appendExtension('.2', from: '.1')))
        ];
        var buildConfigs = parseBuildConfigs({
          'a': {
            'targets': {
              r'$default': {
                'sources': ['lib/*.txt']
              }
            }
          }
        });
        await testBuilders(builders, {'a|lib/a.txt': 'a'},
            overrideBuildConfig: buildConfigs,
            outputs: {'a|lib/a.txt.1': 'a', 'a|lib/a.txt.1.2': 'a'});
      });

      test('early step touches a not-yet-generated asset', () async {
        var copyId = new AssetId('a', 'lib/file.a.copy');
        var builders = [
          applyToRoot(new TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.b'),
              extraWork: (buildStep, _) => buildStep.canRead(copyId))),
          applyToRoot(new TestBuilder(
              buildExtensions: appendExtension('.copy', from: '.a'))),
          applyToRoot(new TestBuilder(
              buildExtensions: appendExtension('.exists', from: '.a'),
              build: writeCanRead(copyId))),
        ];
        await testBuilders(builders, {
          'a|lib/file.a': 'a',
          'a|lib/file.b': 'b',
        }, outputs: {
          'a|lib/file.a.copy': 'a',
          'a|lib/file.b.copy': 'b',
          'a|lib/file.a.exists': 'true',
        });
      });

      test('asset is deleted mid-build, use cached canRead result', () async {
        var aTxtId = new AssetId('a', 'lib/file.a');
        var ready = new Completer();
        var firstBuilder = new TestBuilder(
            buildExtensions: appendExtension('.exists', from: '.a'),
            build: writeCanRead(aTxtId));
        var writer = new InMemoryRunnerAssetWriter();
        var reader = new InMemoryRunnerAssetReader.shareAssetCache(
            writer.assets,
            rootPackage: 'a');
        var builders = [
          applyToRoot(firstBuilder),
          applyToRoot(new TestBuilder(
            buildExtensions: appendExtension('.exists', from: '.b'),
            build: (_, __) => ready.future,
            extraWork: writeCanRead(aTxtId),
          )),
        ];

        // After the first builder runs, delete the asset from the reader and
        // allow the 2nd builder to run.
        //
        // ignore: unawaited_futures
        firstBuilder.buildsCompleted.first.then((_) {
          reader.assets.remove(aTxtId);
          ready.complete();
        });

        await testBuilders(
            builders,
            {
              'a|lib/file.a': '',
              'a|lib/file.b': '',
            },
            outputs: {
              'a|lib/file.a.exists': 'true',
              'a|lib/file.b.exists': 'true',
            },
            reader: reader,
            writer: writer);
      });

      test('pre-existing outputs', () async {
        var writer = new InMemoryRunnerAssetWriter();
        await testBuilders([
          copyABuilderApplication,
          applyToRoot(new TestBuilder(
              buildExtensions: appendExtension('.clone', from: '.copy')))
        ], {
          'a|web/a.txt': 'a',
          'a|web/a.txt.copy': 'a',
        }, outputs: {
          'a|web/a.txt.copy': 'a',
          'a|web/a.txt.copy.clone': 'a'
        }, writer: writer, deleteFilesByDefault: true);

        var graphId = makeAssetId('a|$assetGraphPath');
        expect(writer.assets, contains(graphId));
        var cachedGraph = new AssetGraph.deserialize(writer.assets[graphId]);
        expect(
            cachedGraph.allNodes.map((node) => node.id),
            unorderedEquals([
              makeAssetId('a|web/a.txt'),
              makeAssetId('a|web/a.txt.copy'),
              makeAssetId('a|web/a.txt.copy.clone'),
              makeAssetId('a|Phase0.builderOptions'),
              makeAssetId('a|Phase1.builderOptions'),
            ]..addAll(placeholders)));
        expect(cachedGraph.sources, [makeAssetId('a|web/a.txt')]);
        expect(
            cachedGraph.outputs,
            unorderedEquals([
              makeAssetId('a|web/a.txt.copy'),
              makeAssetId('a|web/a.txt.copy.clone'),
            ]));
      });

      test('in low resources mode', () async {
        await testBuilders(
            [copyABuilderApplication], {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
            outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'},
            enableLowResourcesMode: true);
      });

      test('previous outputs are cleaned up', () async {
        final writer = new InMemoryRunnerAssetWriter();
        await testBuilders([copyABuilderApplication], {'a|web/a.txt': 'a'},
            outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

        var blockingCompleter = new Completer<Null>();
        var builder = new TestBuilder(
            buildExtensions: appendExtension('.copy', from: '.txt'),
            extraWork: (_, __) => blockingCompleter.future);
        var done = testBuilders([applyToRoot(builder)], {'a|web/a.txt': 'b'},
            outputs: {'a|web/a.txt.copy': 'b'}, writer: writer);

        // Before the build starts we should still see the asset, we haven't
        // actually deleted it yet.
        var copyId = makeAssetId('a|web/a.txt.copy');
        expect(writer.assets, contains(copyId));

        // But we should delete it before actually running the builder.
        var inputId = makeAssetId('a|web/a.txt');
        await builder.buildInputs.firstWhere((id) => id == inputId);
        expect(writer.assets, isNot(contains(copyId)));

        // Now let the build finish.
        blockingCompleter.complete();
        await done;
      });
    });

    test('skips builders which would output files in non-root packages',
        () async {
      final packageGraph = buildPackageGraph({
        rootPackage('a', path: 'a/'): ['b'],
        package('b', path: 'a/b'): []
      });
      expect(
          () => testBuilders(
              [
                apply('', [(_) => new TestBuilder()], toPackage('b'),
                    hideOutput: false)
              ],
              {'b|lib/b.txt': 'b'},
              packageGraph: packageGraph,
              outputs: {}),
          throwsA(new TypeMatcher<CannotBuildException>()));
    });

    group('with `hideOutput: true`', () {
      PackageGraph packageGraph;

      setUp(() {
        packageGraph = buildPackageGraph({
          rootPackage('a', path: 'a/'): ['b'],
          package('b', path: 'a/b/'): []
        });
      });
      test('can output files in non-root packages', () async {
        await testBuilders(
            [
              apply('', [(_) => new TestBuilder()], toPackage('b'),
                  hideOutput: true, appliesBuilders: ['a|post_copy_builder']),
              postCopyABuilderApplication,
            ],
            {'b|lib/b.txt': 'b'},
            packageGraph: packageGraph,
            outputs: {
              r'$$b|lib/b.txt.copy': 'b',
              r'$$b|lib/b.txt.post': 'b',
            });
      });

      test('handles mixed hidden and non-hidden outputs', () async {
        await testBuilders(
            [
              applyToRoot(new TestBuilder()),
              applyToRoot(
                  new TestBuilder(
                      buildExtensions: appendExtension('.hiddencopy')),
                  hideOutput: true),
            ],
            {'a|lib/a.txt': 'a'},
            packageGraph: packageGraph,
            outputs: {
              r'$$a|lib/a.txt.hiddencopy': 'a',
              r'$$a|lib/a.txt.copy.hiddencopy': 'a',
              r'a|lib/a.txt.copy': 'a',
            });
      });

      test(
          'disallows reading hidden outputs from another package to create '
          'a non-hidden output', () async {
        await testBuilders(
            [
              apply('hidden_on_b', [(_) => new TestBuilder()], toPackage('b'),
                  hideOutput: true),
              applyToRoot(new TestBuilder(
                  buildExtensions: appendExtension('.check_can_read'),
                  build: writeCanRead(makeAssetId('b|lib/b.txt.copy'))))
            ],
            {'a|lib/a.txt': 'a', 'b|lib/b.txt': 'b'},
            packageGraph: packageGraph,
            outputs: {
              r'$$b|lib/b.txt.copy': 'b',
              r'a|lib/a.txt.check_can_read': 'false',
            });
      });

      test(
          'allows reading hidden outputs from same package to create '
          'a non-hidden output', () async {
        await testBuilders(
            [
              applyToRoot(new TestBuilder(), hideOutput: true),
              applyToRoot(new TestBuilder(
                  buildExtensions: appendExtension('.check_can_read'),
                  build: writeCanRead(makeAssetId('a|lib/a.txt.copy'))))
            ],
            {'a|lib/a.txt': 'a'},
            packageGraph: packageGraph,
            outputs: {
              r'$$a|lib/a.txt.copy': 'a',
              r'a|lib/a.txt.copy.check_can_read': 'true',
              r'a|lib/a.txt.check_can_read': 'true',
            });
      });

      test(
          'disallows reading hidden outputs in dep to create a non-hidden output',
          () async {
        await testBuilders(
            [
              apply('b|hidden', [(_) => new TestBuilder()], toPackage('b'),
                  hideOutput: true),
              applyToRoot(new TestBuilder(
                  buildExtensions: appendExtension('.clone'),
                  build: writeCanRead(makeAssetId('b|lib/b.txt.copy'))))
            ],
            {'a|lib/a.txt': 'a', 'b|lib/b.txt': 'b'},
            packageGraph: packageGraph,
            outputs: {
              r'$$b|lib/b.txt.copy': 'b',
              r'a|lib/a.txt.clone': 'false',
            });
      });

      test('Will not delete from non-root packages', () async {
        var writer = new InMemoryRunnerAssetWriter()
          ..onDelete = (AssetId assetId) {
            if (assetId.package != 'a') {
              throw 'Should not delete outside of package:a, '
                  'tried to delete $assetId';
            }
          };
        await testBuilders(
            [
              apply('', [(_) => new TestBuilder()], toPackage('b'),
                  hideOutput: true)
            ],
            {
              'b|lib/b.txt': 'b',
              'a|.dart_tool/build/generated/b/lib/b.txt.copy': 'b'
            },
            packageGraph: packageGraph,
            writer: writer,
            outputs: {r'$$b|lib/b.txt.copy': 'b'});
      });
    });

    test('can read files from external packages', () async {
      var builders = [
        apply(
            '',
            [
              (_) => new TestBuilder(
                  extraWork: (buildStep, _) =>
                      buildStep.canRead(makeAssetId('b|lib/b.txt')))
            ],
            toRoot(),
            hideOutput: false)
      ];
      await testBuilders(builders, {
        'a|lib/a.txt': 'a',
        'b|lib/b.txt': 'b'
      }, outputs: {
        'a|lib/a.txt.copy': 'a',
      });
    });

    test('can glob files from packages', () async {
      final packageGraph = buildPackageGraph({
        rootPackage('a', path: 'a/'): ['b'],
        package('b', path: 'a/b/'): []
      });

      var builders = [
        apply('', [(_) => globBuilder], toRoot(), hideOutput: true),
        apply('', [(_) => globBuilder], toPackage('b'), hideOutput: true),
      ];

      await testBuilders(
          builders,
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
            r'$$a|lib/a.matchingFiles': 'a|lib/a.txt\na|lib/b.txt\na|web/a.txt',
            r'$$b|lib/b.matchingFiles': 'b|lib/c.txt\nb|lib/d.txt',
          },
          packageGraph: packageGraph);
    });

    test('can glob files with excludes applied', () async {
      await testBuilders(
          [applyToRoot(globBuilder)],
          {
            'a|lib/a/1.txt': '',
            'a|lib/a/2.txt': '',
            'a|lib/b/1.txt': '',
            'a|lib/b/2.txt': '',
            'a|lib/test.globPlaceholder': '',
          },
          overrideBuildConfig: parseBuildConfigs({
            'a': {
              'targets': {
                'a': {
                  'sources': {
                    'exclude': ['lib/a/**']
                  }
                }
              }
            }
          }),
          outputs: {
            'a|lib/test.matchingFiles': 'a|lib/b/1.txt\na|lib/b/2.txt',
          });
    });

    test('can build on files outside the hardcoded whitelist', () async {
      await testBuilders(
          [applyToRoot(new TestBuilder())], {'a|test_files/a.txt': 'a'},
          overrideBuildConfig: parseBuildConfigs({
            'a': {
              'targets': {
                'a': {
                  'sources': ['test_files/**']
                }
              }
            }
          }),
          outputs: {'a|test_files/a.txt.copy': 'a'});
    });

    test('can\'t read files in .dart_tool', () async {
      await testBuilders([
        apply(
            '',
            [
              (_) => new TestBuilder(
                  build: copyFrom(makeAssetId('a|.dart_tool/any_file')))
            ],
            toRoot())
      ], {
        'a|lib/a.txt': 'a',
        'a|.dart_tool/any_file': 'content'
      }, status: BuildStatus.failure);
    });

    test('Overdeclared outputs are not treated as inputs to later steps',
        () async {
      var builders = [
        applyToRoot(new TestBuilder(
            buildExtensions: appendExtension('.unexpected'),
            build: (_, __) {})),
        applyToRoot(
            new TestBuilder(buildExtensions: appendExtension('.expected'))),
        applyToRoot(new TestBuilder()),
      ];
      await testBuilders(builders, {
        'a|lib/a.txt': 'a',
      }, outputs: {
        'a|lib/a.txt.copy': 'a',
        'a|lib/a.txt.expected': 'a',
        'a|lib/a.txt.expected.copy': 'a',
      });
    });

    test('can build files from one dir when building another dir', () async {
      await testBuilders([
        applyToRoot(new TestBuilder(),
            generateFor: new InputSet(include: ['test/*.txt']),
            hideOutput: true),
        applyToRoot(
            new TestBuilder(
                buildExtensions: appendExtension('.copy', from: '.txt'),
                extraWork: (buildStep, _) async {
                  // Should not trigger a.txt.copy to be built.
                  await buildStep.readAsString(new AssetId('a', 'test/a.txt'));
                  // Should trigger b.txt.copy to be built.
                  await buildStep
                      .readAsString(new AssetId('a', 'test/b.txt.copy'));
                }),
            generateFor: new InputSet(include: ['web/*.txt']),
            hideOutput: true),
      ], {
        'a|test/a.txt': 'a',
        'a|test/b.txt': 'b',
        'a|web/a.txt': 'a',
      }, outputs: {
        r'$$a|web/a.txt.copy': 'a',
        r'$$a|test/b.txt.copy': 'b',
      }, buildDirs: [
        'web'
      ], verbose: true);
    });

    test('build to source builders are always ran regardless of buildDirs',
        () async {
      await testBuilders([
        applyToRoot(new TestBuilder(),
            generateFor: new InputSet(include: ['**/*.txt']),
            hideOutput: false),
      ], {
        'a|test/a.txt': 'a',
        'a|web/a.txt': 'a',
      }, outputs: {
        r'a|test/a.txt.copy': 'a',
        r'a|web/a.txt.copy': 'a',
      }, buildDirs: [
        'web'
      ], verbose: true);
    });

    test('can output performance logs', () async {
      var writer = new InMemoryRunnerAssetWriter();
      var reader = new InMemoryRunnerAssetReader.shareAssetCache(writer.assets,
          rootPackage: 'a');
      await testBuilders(
        [
          apply('test_builder', [(_) => new TestBuilder()], toRoot(),
              isOptional: false, hideOutput: false),
        ],
        {'a|web/a.txt': 'a'},
        outputs: {'a|web/a.txt.copy': 'a'},
        writer: writer,
        reader: reader,
        logPerformanceDir: 'perf',
      );
      var logs = await reader.findAssets(new Glob('perf/**')).toList();
      expect(logs.length, 1);
      var perf = new BuildPerformance.fromJson(
          jsonDecode(await reader.readAsString(logs.first))
              as Map<String, dynamic>);
      expect(perf.phases.length, 1);
      expect(perf.phases.first.builderKeys, equals(['test_builder']));
    });
  });

  test('tracks dependency graph in a asset_graph.json file', () async {
    final writer = new InMemoryRunnerAssetWriter();
    await testBuilders([
      requiresPostProcessBuilderApplication,
      postCopyABuilderApplication,
    ], {
      'a|web/a.txt': 'a',
      'a|lib/b.txt': 'b'
    }, outputs: {
      'a|web/a.txt.copy': 'a',
      'a|lib/b.txt.copy': 'b',
      r'$$a|web/a.txt.post': 'a',
      r'$$a|lib/b.txt.post': 'b',
    }, writer: writer);

    var graphId = makeAssetId('a|$assetGraphPath');
    expect(writer.assets, contains(graphId));
    var cachedGraph = new AssetGraph.deserialize(writer.assets[graphId]);

    var expectedGraph = await AssetGraph.build([], new Set(), new Set(),
        buildPackageGraph({rootPackage('a'): []}), null);

    // Source nodes
    var aSourceNode = makeAssetNode('a|web/a.txt', [], computeDigest('a'));
    var bSourceNode = makeAssetNode('a|lib/b.txt', [], computeDigest('b'));
    expectedGraph.add(aSourceNode);
    expectedGraph.add(bSourceNode);

    // Regular generated asset nodes and supporting nodes.
    var builderOptionsId = makeAssetId('a|Phase0.builderOptions');
    var builderOptionsNode = new BuilderOptionsAssetNode(
        builderOptionsId, computeBuilderOptionsDigest(defaultBuilderOptions));
    expectedGraph.add(builderOptionsNode);

    var aCopyNode = new GeneratedAssetNode(makeAssetId('a|web/a.txt.copy'),
        phaseNumber: 0,
        primaryInput: makeAssetId('a|web/a.txt'),
        state: GeneratedNodeState.upToDate,
        wasOutput: true,
        isFailure: false,
        builderOptionsId: builderOptionsId,
        lastKnownDigest: computeDigest('a'),
        inputs: [makeAssetId('a|web/a.txt')],
        isHidden: false);
    builderOptionsNode.outputs.add(aCopyNode.id);
    expectedGraph.add(aCopyNode);
    aSourceNode.outputs.add(aCopyNode.id);
    aSourceNode.primaryOutputs.add(aCopyNode.id);

    var bCopyNode = new GeneratedAssetNode(makeAssetId('a|lib/b.txt.copy'),
        phaseNumber: 0,
        primaryInput: makeAssetId('a|lib/b.txt'),
        state: GeneratedNodeState.upToDate,
        wasOutput: true,
        isFailure: false,
        builderOptionsId: builderOptionsId,
        lastKnownDigest: computeDigest('b'),
        inputs: [makeAssetId('a|lib/b.txt')],
        isHidden: false);
    builderOptionsNode.outputs.add(bCopyNode.id);
    expectedGraph.add(bCopyNode);
    bSourceNode.outputs.add(bCopyNode.id);
    bSourceNode.primaryOutputs.add(bCopyNode.id);

    // Post build generates asset nodes and supporting nodes
    var postBuilderOptionsId = makeAssetId('a|PostPhase0.builderOptions');
    var postBuilderOptionsNode = new BuilderOptionsAssetNode(
        postBuilderOptionsId,
        computeBuilderOptionsDigest(defaultBuilderOptions));
    expectedGraph.add(postBuilderOptionsNode);

    var aAnchorNode = new PostProcessAnchorNode.forInputAndAction(
        aSourceNode.id, 0, postBuilderOptionsId);
    var bAnchorNode = new PostProcessAnchorNode.forInputAndAction(
        bSourceNode.id, 0, postBuilderOptionsId);
    expectedGraph.add(aAnchorNode);
    expectedGraph.add(bAnchorNode);

    var aPostCopyNode = new GeneratedAssetNode(makeAssetId('a|web/a.txt.post'),
        phaseNumber: 1,
        primaryInput: makeAssetId('a|web/a.txt'),
        state: GeneratedNodeState.upToDate,
        wasOutput: true,
        isFailure: false,
        builderOptionsId: postBuilderOptionsId,
        lastKnownDigest: computeDigest('a'),
        inputs: [makeAssetId('a|web/a.txt'), aAnchorNode.id],
        isHidden: true);
    // Note we don't expect this node to get added to the builder options node
    // outputs.
    expectedGraph.add(aPostCopyNode);
    aSourceNode.outputs.add(aPostCopyNode.id);
    aSourceNode.anchorOutputs.add(aAnchorNode.id);
    aAnchorNode.outputs.add(aPostCopyNode.id);
    aSourceNode.primaryOutputs.add(aPostCopyNode.id);

    var bPostCopyNode = new GeneratedAssetNode(makeAssetId('a|lib/b.txt.post'),
        phaseNumber: 1,
        primaryInput: makeAssetId('a|lib/b.txt'),
        state: GeneratedNodeState.upToDate,
        wasOutput: true,
        isFailure: false,
        builderOptionsId: postBuilderOptionsId,
        lastKnownDigest: computeDigest('b'),
        inputs: [makeAssetId('a|lib/b.txt'), bAnchorNode.id],
        isHidden: true);
    // Note we don't expect this node to get added to the builder options node
    // outputs.
    expectedGraph.add(bPostCopyNode);
    bSourceNode.outputs.add(bPostCopyNode.id);
    bSourceNode.anchorOutputs.add(bAnchorNode.id);
    bAnchorNode.outputs.add(bPostCopyNode.id);
    bSourceNode.primaryOutputs.add(bPostCopyNode.id);

    // TODO: We dont have a shared way of computing the combined input hashes
    // today, but eventually we should test those here too.
    expect(cachedGraph,
        equalsAssetGraph(expectedGraph, checkPreviousInputsDigest: false));
  });

  test('outputs from previous full builds shouldn\'t be inputs to later ones',
      () async {
    final writer = new InMemoryRunnerAssetWriter();
    var inputs = <String, String>{'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'};
    var outputs = <String, String>{
      'a|web/a.txt.copy': 'a',
      'a|lib/b.txt.copy': 'b'
    };
    // First run, nothing special.
    await testBuilders([copyABuilderApplication], inputs,
        outputs: outputs, writer: writer);
    // Second run, should have no outputs.
    await testBuilders([copyABuilderApplication], inputs,
        outputs: {}, writer: writer);
  });

  test('can recover from a deleted asset_graph.json cache', () async {
    final writer = new InMemoryRunnerAssetWriter();
    var inputs = <String, String>{'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'};
    var outputs = <String, String>{
      'a|web/a.txt.copy': 'a',
      'a|lib/b.txt.copy': 'b'
    };
    // First run, nothing special.
    await testBuilders([copyABuilderApplication], inputs,
        outputs: outputs, writer: writer);

    // Delete the `asset_graph.json` file!
    var outputId = makeAssetId('a|$assetGraphPath');
    await writer.delete(outputId);

    // Second run, should have no extra outputs.
    var done = testBuilders([copyABuilderApplication], inputs,
        outputs: outputs, writer: writer);
    // Should block on user input.
    await new Future.delayed(new Duration(seconds: 1));
    // Now it should complete!
    await done;
  });

  group('incremental builds with cached graph', () {
    test('one new asset, one modified asset, one unchanged asset', () async {
      var builders = [copyABuilderApplication];

      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testBuilders(
          builders,
          {
            'a|web/a.txt': 'a',
            'a|lib/b.txt': 'b',
          },
          outputs: {
            'a|web/a.txt.copy': 'a',
            'a|lib/b.txt.copy': 'b',
          },
          writer: writer);

      // Followup build with modified inputs.
      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      writer.assets.clear();
      await testBuilders(
          builders,
          {
            'a|web/a.txt': 'a2',
            'a|web/a.txt.copy': 'a',
            'a|lib/b.txt': 'b',
            'a|lib/b.txt.copy': 'b',
            'a|lib/c.txt': 'c',
            'a|$assetGraphPath': serializedGraph,
          },
          outputs: {
            'a|web/a.txt.copy': 'a2',
            'a|lib/c.txt.copy': 'c',
          },
          writer: writer);
    });

    test('graph/file system get cleaned up for deleted inputs', () async {
      var builders = [
        copyABuilderApplication,
        applyToRoot(new TestBuilder(
            buildExtensions: replaceExtension('.copy', '.clone')))
      ];

      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testBuilders(
          builders,
          {
            'a|lib/a.txt': 'a',
          },
          outputs: {
            'a|lib/a.txt.copy': 'a',
            'a|lib/a.txt.clone': 'a',
          },
          writer: writer);

      // Followup build with deleted input + cached graph.
      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      writer.assets.clear();
      await testBuilders(
          builders,
          {
            'a|lib/a.txt.copy': 'a',
            'a|lib/a.txt.clone': 'a',
            'a|$assetGraphPath': serializedGraph,
          },
          outputs: {},
          writer: writer);

      /// Should be deleted using the writer, and removed from the new graph.
      var newGraph = new AssetGraph.deserialize(
          writer.assets[makeAssetId('a|$assetGraphPath')]);
      var aNodeId = makeAssetId('a|lib/a.txt');
      var aCopyNodeId = makeAssetId('a|lib/a.txt.copy');
      var aCloneNodeId = makeAssetId('a|lib/a.txt.copy.clone');
      expect(newGraph.contains(aNodeId), isFalse);
      expect(newGraph.contains(aCopyNodeId), isFalse);
      expect(newGraph.contains(aCloneNodeId), isFalse);
      expect(writer.assets.containsKey(aNodeId), isFalse);
      expect(writer.assets.containsKey(aCopyNodeId), isFalse);
      expect(writer.assets.containsKey(aCloneNodeId), isFalse);
    });

    test('no outputs if no changed sources', () async {
      var builders = [copyABuilderApplication];

      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testBuilders(builders, {'a|web/a.txt': 'a'},
          outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

      // Followup build with same sources + cached graph.
      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      await testBuilders(builders, {
        'a|web/a.txt': 'a',
        'a|web/a.txt.copy': 'a',
        'a|$assetGraphPath': serializedGraph,
      }, outputs: {});
    });

    test('no outputs if no changed sources using `hideOutput: true`', () async {
      var builders = [
        apply('', [(_) => new TestBuilder()], toRoot(), hideOutput: true)
      ];

      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testBuilders(builders, {'a|web/a.txt': 'a'},
          // Note that `testBuilders` converts generated cache dir paths to the
          // original ones for matching.
          outputs: {r'$$a|web/a.txt.copy': 'a'},
          writer: writer);

      // Followup build with same sources + cached graph.
      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      await testBuilders(builders, {
        'a|web/a.txt': 'a',
        'a|web/a.txt.copy': 'a',
        'a|$assetGraphPath': serializedGraph,
      }, outputs: {});
    });

    test('inputs/outputs are updated if they change', () async {
      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testBuilders([
        applyToRoot(new TestBuilder(
            buildExtensions: appendExtension('.copy', from: '.a'),
            build: copyFrom(makeAssetId('a|lib/file.b')))),
      ], {
        'a|lib/file.a': 'a',
        'a|lib/file.b': 'b',
        'a|lib/file.c': 'c',
      }, outputs: {
        'a|lib/file.a.copy': 'b',
      }, writer: writer);

      // Followup build with same sources + cached graph, but configure the
      // builder to read a different file.
      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      writer.assets.clear();

      await testBuilders([
        applyToRoot(new TestBuilder(
            buildExtensions: appendExtension('.copy', from: '.a'),
            build: copyFrom(makeAssetId('a|lib/file.c')))),
      ], {
        'a|lib/file.a': 'a',
        'a|lib/file.a.copy': 'b',
        // Hack to get the file to rebuild, we are being bad by changing the
        // builder but pretending its the same.
        'a|lib/file.b': 'b2',
        'a|lib/file.c': 'c',
        'a|$assetGraphPath': serializedGraph,
      }, outputs: {
        'a|lib/file.a.copy': 'c',
      }, writer: writer);

      // Read cached graph and validate.
      var graph = new AssetGraph.deserialize(
          writer.assets[makeAssetId('a|$assetGraphPath')]);
      var outputNode =
          graph.get(makeAssetId('a|lib/file.a.copy')) as GeneratedAssetNode;
      var fileANode = graph.get(makeAssetId('a|lib/file.a'));
      var fileBNode = graph.get(makeAssetId('a|lib/file.b'));
      var fileCNode = graph.get(makeAssetId('a|lib/file.c'));
      expect(outputNode.inputs, unorderedEquals([fileANode.id, fileCNode.id]));
      expect(fileANode.outputs, contains(outputNode.id));
      expect(fileBNode.outputs, isEmpty);
      expect(fileCNode.outputs, unorderedEquals([outputNode.id]));
    });

    test('Ouputs aren\'t rebuilt if their inputs didn\'t change', () async {
      var builders = [
        applyToRoot(new TestBuilder(
            buildExtensions: appendExtension('.copy', from: '.a'),
            build: copyFrom(makeAssetId('a|lib/file.b')))),
        applyToRoot(new TestBuilder(
            buildExtensions: appendExtension('.copy', from: '.a.copy'))),
      ];

      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testBuilders(
          builders,
          {
            'a|lib/file.a': 'a',
            'a|lib/file.b': 'b',
          },
          outputs: {
            'a|lib/file.a.copy': 'b',
            'a|lib/file.a.copy.copy': 'b',
          },
          writer: writer);

      // Modify the primary input of `file.a.copy`, but its output doesn't
      // change so `file.a.copy.copy` shouldn't be rebuilt.
      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      writer.assets.clear();
      await testBuilders(
          builders,
          {
            'a|lib/file.a': 'a2',
            'a|lib/file.b': 'b',
            'a|lib/file.a.copy': 'b',
            'a|lib/file.a.copy.copy': 'b',
            'a|$assetGraphPath': serializedGraph,
          },
          outputs: {
            'a|lib/file.a.copy': 'b',
          },
          writer: writer);
    });
  });

  group('regression tests', () {
    test(
        'a failed output on a primary input which is not output in later builds',
        () async {
      var builders = [
        applyToRoot(new TestBuilder(
            buildExtensions: replaceExtension('.source', '.g1'),
            build: (buildStep, _) async {
              var content = await buildStep.readAsString(buildStep.inputId);
              if (content == 'true') {
                await buildStep.writeAsString(
                    buildStep.inputId.changeExtension('.g1'), '');
              }
            })),
        applyToRoot(new TestBuilder(
            buildExtensions: replaceExtension('.g1', '.g2'),
            build: (buildStep, _) {
              throw 'Fails always';
            })),
      ];
      var writer = new InMemoryRunnerAssetWriter();
      await testBuilders(
        builders,
        {'a|lib/a.source': 'true'},
        status: BuildStatus.failure,
        writer: writer,
      );

      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      writer.assets.clear();

      await testBuilders(
          builders,
          {
            'a|lib/a.source': 'false',
            'a|$assetGraphPath': serializedGraph,
          },
          outputs: {},
          writer: writer);
    });

    test('the entrypoint cannot be read by a builder', () async {
      var builders = [
        applyToRoot(new TestBuilder(
            buildExtensions: replaceExtension('.txt', '.hasEntrypoint'),
            build: (buildStep, _) async {
              var hasEntrypoint = await buildStep
                  .findAssets(new Glob('**'))
                  .contains(
                      makeAssetId('a|.dart_tool/build/entrypoint/build.dart'));
              await buildStep.writeAsString(
                  buildStep.inputId.changeExtension('.hasEntrypoint'),
                  '$hasEntrypoint');
            }))
      ];
      await testBuilders(
        builders,
        {
          'a|lib/a.txt': 'a',
          'a|.dart_tool/build/entrypoint/build.dart': 'some build script',
        },
        outputs: {'a|lib/a.hasEntrypoint': 'false'},
      );
    });
  });
}
