// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';

import 'package:build_runner/build_runner.dart';
import 'package:build_runner/src/asset_graph/exceptions.dart';
import 'package:build_runner/src/asset_graph/graph.dart';
import 'package:build_runner/src/asset_graph/node.dart';

import '../common/common.dart';

void main() {
  /// Basic phases/phase groups which get used in many tests
  final copyABuildAction = new BuildAction(new CopyBuilder(), 'a');
  final globBuilder = new GlobbingBuilder(new Glob('**.txt'));
  final txtFilePackageBuilderAction = new PackageBuildAction(
      new TxtFilePackageBuilder(
          'a', {'web/hello.txt': 'hello', 'web/world.txt': 'world'}),
      'a');

  group('build', () {
    group('with root package inputs', () {
      test('one phase, one builder, one-to-one outputs', () async {
        await testActions(
            [copyABuildAction], {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
            outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'});
      });

      test('one phase, one builder, one-to-many outputs', () async {
        await testActions([
          new BuildAction(new CopyBuilder(numCopies: 2), 'a')
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

      test('one package builder', () async {
        await testActions([txtFilePackageBuilderAction], {},
            outputs: {'a|web/hello.txt': 'hello', 'a|web/world.txt': 'world'});
      });

      test('optional build actions don\'t run if their outputs aren\'t read',
          () async {
        await testActions([
          new PackageBuildAction(
              new TxtFilePackageBuilder('a', {'web/a.txt': 'a'}), 'a',
              isOptional: true),
          new BuildAction(new CopyBuilder(extension: '1'), 'a',
              isOptional: true),
          new BuildAction(new CopyBuilder(extension: '2'), 'a',
              isOptional: true, inputs: ['**.1']),
        ], {}, outputs: {});
      });

      test('optional build actions do run if their outputs are read', () async {
        await testActions([
          new PackageBuildAction(
              new TxtFilePackageBuilder('a', {'web/a.txt': 'a'}), 'a',
              isOptional: true),
          new BuildAction(new CopyBuilder(extension: '1'), 'a',
              isOptional: true),
          new BuildAction(new CopyBuilder(extension: '2'), 'a',
              isOptional: true, inputs: ['**.1']),
          new BuildAction(new CopyBuilder(extension: '3'), 'a',
              inputs: ['**.2']),
        ], {}, outputs: {
          'a|web/a.txt': 'a',
          'a|web/a.txt.1': 'a',
          'a|web/a.txt.1.2': 'a',
          'a|web/a.txt.1.2.3': 'a',
        });
      });

      test('multiple mixed build actions', () async {
        var buildActions = [
          copyABuildAction,
          new BuildAction(new CopyBuilder(extension: 'clone'), 'a',
              inputs: ['**/*.txt'], isOptional: true),
          txtFilePackageBuilderAction,
          new BuildAction(new CopyBuilder(numCopies: 2), 'a',
              inputs: ['web/*.txt.clone']),
          new BuildAction(new CopyBuilder(), 'a', inputs: ['web/hello.txt']),
        ];
        await testActions(buildActions, {
          'a|web/a.txt': 'a',
          'a|lib/b.txt': 'b',
        }, outputs: {
          'a|web/a.txt.copy': 'a',
          'a|web/a.txt.clone': 'a',
          'a|lib/b.txt.copy': 'b',
          // No b.txt.clone since nothing else read it and its optional.
          'a|web/a.txt.clone.copy.0': 'a',
          'a|web/a.txt.clone.copy.1': 'a',
          'a|web/hello.txt': 'hello',
          'a|web/world.txt': 'world',
          'a|web/hello.txt.copy': 'hello',
        });
      });

      test('early step touches a not-yet-generated asset', () async {
        var copyId = new AssetId('a', 'lib/a.txt.copy');
        var buildActions = [
          new BuildAction(new CopyBuilder(touchAsset: copyId), 'a',
              inputs: ['lib/b.txt']),
          new BuildAction(new CopyBuilder(), 'a', inputs: ['lib/a.txt']),
          new BuildAction(new ExistsBuilder(copyId), 'a', inputs: ['lib/a.txt'])
        ];
        await testActions(buildActions, {
          'a|lib/a.txt': 'a',
          'a|lib/b.txt': 'b',
        }, outputs: {
          'a|lib/a.txt.exists': 'true',
          'a|lib/a.txt.copy': 'a',
          'a|lib/b.txt.copy': 'b',
        });
      });

      test('asset is deleted mid-build, use cached canRead result', () async {
        var aTxtId = new AssetId('a', 'lib/a.txt');
        var ready = new Completer();
        var firstBuilder = new ExistsBuilder(aTxtId);
        var writer = new InMemoryRunnerAssetWriter();
        var reader = new InMemoryRunnerAssetReader(writer.assets, 'a');
        var buildActions = [
          new BuildAction(firstBuilder, 'a', inputs: ['lib/a.txt']),
          new BuildAction(new ExistsBuilder(aTxtId, waitFor: ready.future), 'a',
              inputs: ['lib/b.txt']),
        ];

        // After the first builder runs, delete the asset from the reader and
        // allow the 2nd builder to run.
        //
        // ignore: unawaited_futures
        firstBuilder.hasRan.then((_) {
          reader.assets.remove(aTxtId);
          ready.complete();
        });

        await testActions(
            buildActions,
            {
              'a|lib/a.txt': '',
              'a|lib/b.txt': '',
            },
            outputs: {
              'a|lib/a.txt.exists': 'true',
              'a|lib/b.txt.exists': 'true',
            },
            reader: reader,
            writer: writer);
      });

      test('one phase, one builder, one-to-one outputs', () async {
        await testActions(
            [copyABuildAction], {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
            outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'});
      });

      test('pre-existing outputs', () async {
        var writer = new InMemoryRunnerAssetWriter();
        await testActions([
          copyABuildAction,
          new BuildAction(new CopyBuilder(extension: 'clone'), 'a',
              inputs: ['**.txt.copy'])
        ], {
          'a|web/a.txt': 'a',
          'a|web/a.txt.copy': 'a',
        }, outputs: {
          'a|web/a.txt.copy': 'a',
          'a|web/a.txt.copy.clone': 'a'
        }, writer: writer, deleteFilesByDefault: true);

        var graphId = makeAssetId('a|$assetGraphPath');
        expect(writer.assets, contains(graphId));
        var cachedGraph = new AssetGraph.deserialize(
            JSON.decode(UTF8.decode(writer.assets[graphId])) as Map);
        expect(
            cachedGraph.allNodes.map((node) => node.id),
            unorderedEquals([
              makeAssetId('a|web/a.txt'),
              makeAssetId('a|web/a.txt.copy'),
              makeAssetId('a|web/a.txt.copy.clone'),
            ]));
        expect(cachedGraph.sources, [makeAssetId('a|web/a.txt')]);
        expect(
            cachedGraph.outputs,
            unorderedEquals([
              makeAssetId('a|web/a.txt.copy'),
              makeAssetId('a|web/a.txt.copy.clone'),
            ]));
      });

      test('in low resources mode', () async {
        await testActions(
            [copyABuildAction], {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
            outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'},
            enableLowResourcesMode: true);
      });
    });

    test('can\'t output files in non-root packages', () async {
      var packageB = new PackageNode(
          'b', '0.1.0', PackageDependencyType.path, 'a/b/',
          includes: ['**']);
      var packageA =
          new PackageNode('a', '0.1.0', PackageDependencyType.path, 'a/')
            ..dependencies.add(packageB);
      var packageGraph = new PackageGraph.fromRoot(packageA);
      expect(
          testActions(
              [new BuildAction(new CopyBuilder(), 'b')], {'b|lib/b.txt': 'b'},
              packageGraph: packageGraph),
          throwsA(anything));
    });

    group('with `writeToCache: true`', () {
      PackageGraph packageGraph;

      setUp(() {
        var packageB = new PackageNode(
            'b', '0.1.0', PackageDependencyType.path, 'a/b/',
            includes: ['**']);
        var packageA =
            new PackageNode('a', '0.1.0', PackageDependencyType.path, 'a/')
              ..dependencies.add(packageB);
        packageGraph = new PackageGraph.fromRoot(packageA);
      });
      test('can output files in non-root packages', () async {
        await testActions(
            [
              new BuildAction(new CopyBuilder(), 'b'),
              new PackageBuildAction(
                  new TxtFilePackageBuilder('b', {'lib/hello.txt': 'hello'}),
                  'b')
            ],
            {'b|lib/b.txt': 'b'},
            packageGraph: packageGraph,
            outputs: {
              'b|lib/b.txt.copy': 'b',
              'b|lib/hello.txt': 'hello',
            },
            writeToCache: true);
      });

      test(
          'PackageBuilder can\'t output files outside of `lib` in non-root '
          'packages.', () async {
        expect(
            testActions(
                [
                  new PackageBuildAction(
                      new TxtFilePackageBuilder(
                          'b', {'web/hello.txt': 'hello'}),
                      'b')
                ],
                {},
                packageGraph: packageGraph,
                outputs: {
                  'b|web/hello.txt': 'hello',
                },
                writeToCache: true),
            throwsA(new isInstanceOf<InvalidPackageBuilderOutputsException>()));
      });

      test('Will not delete from non-root packages', () async {
        var writer = new InMemoryRunnerAssetWriter()
          ..onDelete = (AssetId assetId) {
            if (assetId.package != 'a') {
              throw 'Should not delete outside of package:a, '
                  'tried to delete $assetId';
            }
          };
        await testActions(
            [new BuildAction(new CopyBuilder(), 'b')],
            {
              'b|lib/b.txt': 'b',
              'a|.dart_tool/build/generated/b/lib/b.txt.copy': 'b'
            },
            packageGraph: packageGraph,
            writer: writer,
            outputs: {'b|lib/b.txt.copy': 'b'},
            writeToCache: true);
      });
    });

    test('can read files from external packages', () async {
      var buildActions = [
        new BuildAction(
            new CopyBuilder(touchAsset: makeAssetId('b|lib/b.txt')), 'a')
      ];
      await testActions(buildActions, {
        'a|lib/a.txt': 'a',
        'b|lib/b.txt': 'b'
      }, outputs: {
        'a|lib/a.txt.copy': 'a',
      });
    });

    test('can glob files from packages', () async {
      var packageB =
          new PackageNode('b', '0.1.0', PackageDependencyType.path, 'a/b/');
      var packageA = new PackageNode(
          'a', '0.1.0', PackageDependencyType.path, 'a/',
          includes: ['**'])
        ..dependencies.add(packageB);
      var packageGraph = new PackageGraph.fromRoot(packageA);

      var buildActions = [
        new BuildAction(globBuilder, 'a'),
        new BuildAction(globBuilder, 'b'),
      ];

      await testActions(
          buildActions,
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
            'a|lib/a.matchingFiles': 'a|lib/a.txt\na|lib/b.txt\na|web/a.txt',
            'b|lib/b.matchingFiles': 'b|lib/c.txt\nb|lib/d.txt',
          },
          packageGraph: packageGraph,
          writeToCache: true);
    });

    test('can glob files from packages with excludes applied', () async {
      await testActions([
        new BuildAction(new CopyBuilder(), 'a', excludes: ['lib/a/*.txt'])
      ], {
        'a|lib/a/1.txt': '',
        'a|lib/a/2.txt': '',
        'a|lib/b/1.txt': '',
        'a|lib/b/2.txt': '',
      }, outputs: {
        'a|lib/b/1.txt.copy': '',
        'a|lib/b/2.txt.copy': '',
      }, writeToCache: true);
    });

    test('can\'t read files in .dart_tool', () async {
      await testActions([
        new BuildAction(
            new CopyBuilder(
                copyFromAsset: makeAssetId('a|.dart_tool/any_file')),
            'a')
      ], {
        'a|lib/a.txt': 'a',
        'a|.dart_tool/any_file': 'content'
      }, status: BuildStatus.failure);
    });

    test('won\'t try to delete files from other packages', () async {
      var packageB = new PackageNode(
          'b', '0.1.0', PackageDependencyType.path, 'a/b/',
          includes: ['**']);
      var packageA =
          new PackageNode('a', '0.1.0', PackageDependencyType.path, 'a/')
            ..dependencies.add(packageB);
      var packageGraph = new PackageGraph.fromRoot(packageA);
      var writer = new InMemoryRunnerAssetWriter()
        ..onDelete = (AssetId assetId) {
          if (assetId.package != 'a') {
            throw 'Should not delete outside of package:a';
          }
        };
      await testActions([new BuildAction(new CopyBuilder(), 'a')],
          {'a|lib/a.txt': 'a', 'b|lib/b.txt': 'b', 'b|lib/b.txt.copy': 'b'},
          packageGraph: packageGraph,
          writer: writer,
          outputs: {
            'a|lib/a.txt.copy': 'a',
          });
    });

    test('Overdeclared outputs are not treated as inputs to later steps',
        () async {
      var buildActions = [
        new BuildAction(
            new OverDeclaringCopyBuilder(numCopies: 1, extension: 'unexpected'),
            'a'),
        new BuildAction(
            new CopyBuilder(numCopies: 1, extension: 'expected'), 'a'),
        new BuildAction(new CopyBuilder(numCopies: 1), 'a',
            inputs: ['**.expected', '**.unexpected']),
      ];
      await testActions(buildActions, {
        'a|lib/a.txt': 'a',
      }, outputs: {
        'a|lib/a.txt.expected': 'a',
        'a|lib/a.txt.expected.copy': 'a',
      });
    });
  });

  test('tracks dependency graph in a asset_graph.json file', () async {
    final writer = new InMemoryRunnerAssetWriter();
    await testActions(
        [copyABuildAction], {'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'},
        outputs: {'a|web/a.txt.copy': 'a', 'a|lib/b.txt.copy': 'b'},
        writer: writer);

    var graphId = makeAssetId('a|$assetGraphPath');
    expect(writer.assets, contains(graphId));
    var cachedGraph = new AssetGraph.deserialize(
        JSON.decode(UTF8.decode(writer.assets[graphId])) as Map);

    var expectedGraph = await AssetGraph.build([], new Set(), 'a', null);
    var aCopyNode = new GeneratedAssetNode(null, makeAssetId('a|web/a.txt'),
        false, true, makeAssetId('a|web/a.txt.copy'),
        lastKnownDigest: computeDigest('a'),
        inputs: [makeAssetId('a|web/a.txt')]);
    expectedGraph.add(aCopyNode);
    expectedGraph
        .add(makeAssetNode('a|web/a.txt', [aCopyNode.id], computeDigest('a')));
    var bCopyNode = new GeneratedAssetNode(null, makeAssetId('a|lib/b.txt'),
        false, true, makeAssetId('a|lib/b.txt.copy'),
        lastKnownDigest: computeDigest('b'),
        inputs: [makeAssetId('a|lib/b.txt')]);
    expectedGraph.add(bCopyNode);
    expectedGraph
        .add(makeAssetNode('a|lib/b.txt', [bCopyNode.id], computeDigest('b')));

    expect(cachedGraph, equalsAssetGraph(expectedGraph));
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
    await testActions([copyABuildAction], inputs,
        outputs: outputs, writer: writer);
    // Second run, should have no outputs.
    await testActions([copyABuildAction], inputs, outputs: {}, writer: writer);
  });

  test('can recover from a deleted asset_graph.json cache', () async {
    final writer = new InMemoryRunnerAssetWriter();
    var inputs = <String, String>{'a|web/a.txt': 'a', 'a|lib/b.txt': 'b'};
    var outputs = <String, String>{
      'a|web/a.txt.copy': 'a',
      'a|lib/b.txt.copy': 'b'
    };
    // First run, nothing special.
    await testActions([copyABuildAction], inputs,
        outputs: outputs, writer: writer);

    // Delete the `asset_graph.json` file!
    var outputId = makeAssetId('a|$assetGraphPath');
    await writer.delete(outputId);

    // Second run, should have no extra outputs.
    var done = testActions([copyABuildAction], inputs,
        outputs: outputs, writer: writer);
    // Should block on user input.
    await new Future.delayed(new Duration(seconds: 1));
    // Now it should complete!
    await done;
  });

  group('incremental builds with cached graph', () {
    test('one new asset, one modified asset, one unchanged asset', () async {
      var buildActions = [copyABuildAction];

      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testActions(
          buildActions,
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
      await testActions(
          buildActions,
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
      var buildActions = [
        copyABuildAction,
        new BuildAction(new CopyBuilder(extension: 'clone'), 'a',
            inputs: ['**/*.txt.copy'])
      ];

      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testActions(
          buildActions,
          {
            'a|lib/a.txt': 'a',
          },
          outputs: {
            'a|lib/a.txt.copy': 'a',
            'a|lib/a.txt.copy.clone': 'a',
          },
          writer: writer);

      // Followup build with deleted input + cached graph.
      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      writer.assets.clear();
      await testActions(
          buildActions,
          {
            'a|lib/a.txt.copy': 'a',
            'a|lib/a.txt.copy.clone': 'a',
            'a|$assetGraphPath': serializedGraph,
          },
          outputs: {},
          writer: writer);

      /// Should be deleted using the writer, and removed from the new graph.
      var serialized = JSON.decode(
          UTF8.decode(writer.assets[makeAssetId('a|$assetGraphPath')])) as Map;
      var newGraph = new AssetGraph.deserialize(serialized);
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
      var buildActions = [copyABuildAction];

      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testActions(buildActions, {'a|web/a.txt': 'a'},
          outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

      // Followup build with same sources + cached graph.
      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      await testActions(buildActions, {
        'a|web/a.txt': 'a',
        'a|web/a.txt.copy': 'a',
        'a|$assetGraphPath': serializedGraph,
      }, outputs: {});
    });

    test('no outputs if no changed sources using `writeToCache`', () async {
      var buildActions = [copyABuildAction];

      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testActions(buildActions, {'a|web/a.txt': 'a'},
          // Note that `testActions` converts generated cache dir paths to the
          // original ones for matching.
          outputs: {'a|web/a.txt.copy': 'a'},
          writer: writer,
          writeToCache: true);

      // Followup build with same sources + cached graph.
      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      await testActions(
          buildActions,
          {
            'a|web/a.txt': 'a',
            'a|web/a.txt.copy': 'a',
            'a|$assetGraphPath': serializedGraph,
          },
          outputs: {},
          writeToCache: true);
    });

    test('inputs/outputs are updated if they change', () async {
      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testActions([
        new BuildAction(
            new CopyBuilder(copyFromAsset: makeAssetId('a|lib/b.txt')), 'a',
            inputs: ['lib/a.txt'])
      ], {
        'a|lib/a.txt': 'a',
        'a|lib/b.txt': 'b',
        'a|lib/c.txt': 'c',
      }, outputs: {
        'a|lib/a.txt.copy': 'b',
      }, writer: writer);

      // Followup build with same sources + cached graph, but configure the
      // builder to read a different file.
      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      writer.assets.clear();

      await testActions([
        new BuildAction(
            new CopyBuilder(copyFromAsset: makeAssetId('a|lib/c.txt')), 'a',
            inputs: ['lib/a.txt'])
      ], {
        'a|lib/a.txt': 'a',
        'a|lib/a.txt.copy': 'b',
        // Hack to get the file to rebuild, we are being bad by changing the
        // builder but pretending its the same.
        'a|lib/b.txt': 'b2',
        'a|lib/c.txt': 'c',
        'a|$assetGraphPath': serializedGraph,
      }, outputs: {
        'a|lib/a.txt.copy': 'c',
      }, writer: writer);

      // Read cached graph and validate.
      var graph = new AssetGraph.deserialize(JSON.decode(
          UTF8.decode(writer.assets[makeAssetId('a|$assetGraphPath')])) as Map);
      var outputNode =
          graph.get(makeAssetId('a|lib/a.txt.copy')) as GeneratedAssetNode;
      var aTxtNode = graph.get(makeAssetId('a|lib/a.txt'));
      var bTxtNode = graph.get(makeAssetId('a|lib/b.txt'));
      var cTxtNode = graph.get(makeAssetId('a|lib/c.txt'));
      expect(outputNode.inputs, unorderedEquals([aTxtNode.id, cTxtNode.id]));
      expect(aTxtNode.outputs, contains(outputNode.id));
      expect(bTxtNode.outputs, isEmpty);
      expect(cTxtNode.outputs, unorderedEquals([outputNode.id]));
    });

    test('Ouputs aren\'t rebuilt if their inputs didn\'t change', () async {
      var buildActions = [
        new BuildAction(
            new CopyBuilder(copyFromAsset: new AssetId('a', 'lib/b.txt')), 'a',
            inputs: ['lib/a.txt']),
        new BuildAction(new CopyBuilder(), 'a', inputs: ['lib/a.txt.copy']),
      ];

      // Initial build.
      var writer = new InMemoryRunnerAssetWriter();
      await testActions(
          buildActions,
          {
            'a|lib/a.txt': 'a',
            'a|lib/b.txt': 'b',
          },
          outputs: {
            'a|lib/a.txt.copy': 'b',
            'a|lib/a.txt.copy.copy': 'b',
          },
          writer: writer);

      // Modify the primary input of `a.txt.copy`, but its output doesn't change
      // so `a.txt.copy.copy` shouldn't be rebuilt.
      var serializedGraph = writer.assets[makeAssetId('a|$assetGraphPath')];
      writer.assets.clear();
      await testActions(
          buildActions,
          {
            'a|lib/a.txt': 'a2',
            'a|lib/b.txt': 'b',
            'a|lib/a.txt.copy': 'b',
            'a|lib/a.txt.copy.copy': 'b',
            'a|$assetGraphPath': serializedGraph,
          },
          outputs: {
            'a|lib/a.txt.copy': 'b',
          },
          writer: writer);
    });
  });
}
